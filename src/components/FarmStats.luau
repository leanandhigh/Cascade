--[[
	FarmStats
	Full-screen farm stats screen (its own ScreenGui, outside the window): a black backdrop with
	one card — logo, title, status pill, a big session timer, stat tiles and a materials grid
	(owned count + gain). The game doesn't need drawing behind an opaque screen, so 3D
	rendering is turned off while it's shown (big FPS / CPU save on long farms).

	local farmStats = app:FarmStats({
		Title = "MTwin HUB",
		Subtitle = "Anime Adventures",
		Icon = LOGO,                                -- logo tile (defaults to a chart icon)
		Status = "Online",                          -- pill; StatusKind = "Added" | "Changed" | "Removed" | "Info"
		Stats = {                                   -- tiles (usually 4)
			{ Name = "Level", Value = 225 },
			{ Name = "Money", Value = 8433620 },
			{ Name = "Materials", Value = 101891 },
			{ Name = "Gems", Value = 33125, Format = "short", PerHour = true },
		},
		Materials = {
			{ Name = "Ore", Count = 70, Gain = 2, Icon = 1234567 },
		},
		Footer = "The script keeps running behind this screen",
		Disable3D = true,                           -- default; false keeps the world drawing
		Visible = false,
	})

	farmStats:Show() / :Hide() / :Toggle()
	farmStats:Set("Level", 226) / :Increment("Gems", 50) / :SetStats({ Level = 226, Money = 9e6 })
	farmStats:SetMaterials({ ... }) / :UpdateMaterial("Ore", 72, 4)
	farmStats:SetStatus("Farming", "Added")
	farmStats:Reset()                             -- new session (timer + starting values)

	app:FarmHud({ Source = farmStats })           -- the small HUD can show the same stats
]]

local types = require("@types")

--// Constants
local CARD_WIDTH = 760

return function(self, properties: types.FarmStatsProperties): types.FarmStats
	--// Imports
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")
	local services = require("@modules/services")
	local utility = require("@modules/utility")
	local icons = require("@modules/icons")
	local Store = require("@modules/statStore")

	--// References
	local create = creator.Create
	local tweenService = services.TweenService
	local runService = services.RunService

	--// Constants
	local REGULAR = Font.new("rbxassetid://12187365364", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
	local SEMIBOLD = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
	local BOLD = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal)

	--// Variables
	local theme = self.Theme
	local structures = {}
	local tiles = {} -- name -> { Frame, Value, Rate, Caption }
	local materialRefs = {}
	local materialRows = {}
	local materials = {}
	local shown = false
	local sessionStart = os.clock()
	local startedAt = os.date("%H:%M")
	local statusKind = "Added"
	local customLogo = false
	local object

	--// UI
	properties = properties or {}
	properties.Title = properties.Title or "Farm"
	properties.Subtitle = properties.Subtitle or "Farm session"

	local store = Store.new(properties.Stats)

	local function text(props)
		props.BackgroundTransparency = 1
		props.FontFace = props.FontFace or REGULAR

		return create("TextLabel")(props)
	end

	local function secondary(props)
		props.__dynamicKeys = {
			TextColor3 = theme.Text.Secondary[1],
			TextTransparency = theme.Text.Secondary[2],
		}

		return text(props)
	end

	local function primary(props)
		props.__dynamicKeys = {
			TextColor3 = theme.Text.Primary[1],
			TextTransparency = theme.Text.Primary[2],
		}

		return text(props)
	end

	local function tileFrame(props)
		props.BorderSizePixel = 0
		props.__dynamicKeys = {
			BackgroundColor3 = theme.Controls.Card.Fill[1],
			BackgroundTransparency = theme.Controls.Card.Fill[2],
		}

		table.insert(props, create("UICorner")({ CornerRadius = UDim.new(0, 8) }))
		table.insert(
			props,
			create("UIStroke")({
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

				__dynamicKeys = {
					Color = theme.Controls.ViewBorder[1],
					Transparency = theme.Controls.ViewBorder[2],
				},
			})
		)

		return create("Frame")(props)
	end

	-- A darker shade of the window background: near-black in Dark, soft grey in Light
	local function backdropColor(): Color3
		local base = theme.Controls.Background[1].Value
		local _, _, brightness = base:ToHSV()

		return base:Lerp(Color3.new(0, 0, 0), brightness > 0.5 and 0.1 or 0.55)
	end

	structures.Gui = create("ScreenGui")({
		Name = "CascadeFarmStats",
		DisplayOrder = 1000,
		Enabled = false,
		IgnoreGuiInset = true,
		OnTopOfCoreBlur = true,
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

		create("Frame")({
			Name = "Backdrop",
			Active = true, -- swallows clicks so the game behind isn't touched
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),

			BackgroundColor3 = backdropColor(),
			__contextKeys = {
				BackgroundColor3 = backdropColor,
			},

			-- faint accent glow from the top
			create("Frame")({
				Name = "Glow",
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 0.45),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Selection[1],
				},

				create("UIGradient")({
					Rotation = 90,
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0.86),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),
		}),

		create("Frame")({
			Name = "Center",
			AnchorPoint = Vector2.new(0.5, 0.5),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CARD_WIDTH, 0),

			create("UIScale")({
				Name = "Fit",
			}),

			create("UIListLayout")({
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 14),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("Frame")({
				Name = "Card",
				AutomaticSize = Enum.AutomaticSize.Y,
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 0),

				__dynamicKeys = {
					BackgroundColor3 = theme.Controls.Background[1],
				},

				create("UICorner")({
					CornerRadius = UDim.new(0, 12),
				}),

				create("UIStroke")({
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

					__dynamicKeys = {
						Color = theme.Controls.ViewBorder[1],
						Transparency = theme.Controls.ViewBorder[2],
					},
				}),

				create("UIPadding")({
					PaddingBottom = UDim.new(0, 24),
					PaddingLeft = UDim.new(0, 28),
					PaddingRight = UDim.new(0, 26),
					PaddingTop = UDim.new(0, 24),
				}),

				create("UIListLayout")({
					Padding = UDim.new(0, 20),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				-- Header
				create("Frame")({
					Name = "Header",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 56),

					create("Frame")({
						Name = "LogoTile",
						BorderSizePixel = 0,
						Size = UDim2.fromOffset(56, 56),

						__dynamicKeys = {
							BackgroundColor3 = theme.Controls.View[1],
						},

						create("UICorner")({
							CornerRadius = UDim.new(0, 12),
						}),

						create("UIStroke")({
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Transparency = 0.45,

							__dynamicKeys = {
								Color = theme.Controls.Selection[1],
							},
						}),

						create("ImageLabel")({
							Name = "Logo",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							Position = UDim2.fromScale(0.5, 0.5),
							ScaleType = Enum.ScaleType.Fit,
							Size = UDim2.fromOffset(38, 38),

							__contextKeys = {
								ImageColor3 = function()
									return customLogo and Color3.new(1, 1, 1) or theme.Controls.Selection[1].Value
								end,
							},

							create("UICorner")({
								CornerRadius = UDim.new(0, 8),
							}),
						}),
					}),

					primary({
						Name = "Title",
						FontFace = SEMIBOLD,
						Position = UDim2.fromOffset(72, 6),
						Size = UDim2.new(1, -240, 0, 24),
						Text = "",
						TextSize = 20,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					secondary({
						Name = "Subtitle",
						Position = UDim2.fromOffset(72, 33),
						Size = UDim2.new(1, -240, 0, 18),
						Text = "",
						TextSize = 13,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					create("Frame")({
						Name = "Status",
						AnchorPoint = Vector2.new(1, 0.5),
						AutomaticSize = Enum.AutomaticSize.X,
						BorderSizePixel = 0,
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(0, 30),

						__dynamicKeys = {
							BackgroundColor3 = theme.Controls.View[1],
						},

						create("UICorner")({
							CornerRadius = UDim.new(1, 0),
						}),

						create("UIStroke")({
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

							__dynamicKeys = {
								Color = theme.Controls.ViewBorder[1],
								Transparency = theme.Controls.ViewBorder[2],
							},
						}),

						create("UIPadding")({
							PaddingLeft = UDim.new(0, 12),
							PaddingRight = UDim.new(0, 14),
						}),

						create("UIListLayout")({
							FillDirection = Enum.FillDirection.Horizontal,
							Padding = UDim.new(0, 8),
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),

						create("Frame")({
							Name = "Dot",
							BorderSizePixel = 0,
							Size = UDim2.fromOffset(8, 8),

							create("UICorner")({
								CornerRadius = UDim.new(1, 0),
							}),
						}),

						primary({
							Name = "Label",
							LayoutOrder = 1,
							Size = UDim2.fromOffset(0, 18),
							Text = "",
							TextSize = 13,
						}),
					}),
				}),

				-- Divider with a light sweeping across it
				create("Frame")({
					Name = "Divider",
					BorderSizePixel = 0,
					ClipsDescendants = true,
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 1),

					__dynamicKeys = {
						BackgroundColor3 = theme.Controls.ViewBorder[1],
						BackgroundTransparency = theme.Controls.ViewBorder[2],
					},

					create("Frame")({
						Name = "Sweep",
						BorderSizePixel = 0,
						Position = UDim2.fromScale(-0.3, 0),
						Size = UDim2.fromScale(0.3, 1),

						__dynamicKeys = {
							BackgroundColor3 = theme.Controls.Selection[1],
						},

						create("UIGradient")({
							Transparency = NumberSequence.new({
								NumberSequenceKeypoint.new(0, 1),
								NumberSequenceKeypoint.new(0.5, 0),
								NumberSequenceKeypoint.new(1, 1),
							}),
						}),
					}),
				}),

				-- Session timer
				create("Frame")({
					Name = "TimerRow",
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 82),

					secondary({
						Name = "Caption",
						FontFace = SEMIBOLD,
						Size = UDim2.new(0.6, 0, 0, 14),
						Text = "SESSION TIME",
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					primary({
						Name = "Timer",
						FontFace = BOLD,
						Position = UDim2.fromOffset(-2, 16),
						Size = UDim2.new(0.6, 0, 0, 64),
						Text = "00:00:00",
						TextSize = 58,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					create("Frame")({
						Name = "Meta",
						AnchorPoint = Vector2.new(1, 1),
						BackgroundTransparency = 1,
						Position = UDim2.new(1, 0, 1, -8),
						Size = UDim2.new(0.4, 0, 0, 40),

						create("UIListLayout")({
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							Padding = UDim.new(0, 4),
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Bottom,
						}),

						secondary({
							Name = "Started",
							Size = UDim2.new(1, 0, 0, 16),
							Text = "",
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Right,
						}),

						secondary({
							Name = "Running",
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, 16),
							Text = "",
							TextSize = 12,
							TextXAlignment = Enum.TextXAlignment.Right,
						}),
					}),
				}),

				-- Stat tiles
				create("Frame")({
					Name = "Stats",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Size = UDim2.fromScale(1, 0),

					create("UIGridLayout")({
						CellPadding = UDim2.fromOffset(12, 12),
						CellSize = UDim2.new(0.25, -9, 0, 74),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),

				-- Materials
				create("Frame")({
					Name = "MaterialsHead",
					BackgroundTransparency = 1,
					LayoutOrder = 4,
					Size = UDim2.new(1, 0, 0, 14),

					secondary({
						Name = "Caption",
						FontFace = SEMIBOLD,
						Size = UDim2.fromScale(0.5, 1),
						Text = "MATERIALS",
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),

					secondary({
						Name = "Count",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.fromScale(0.5, 1),
						Text = "",
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),

				create("Frame")({
					Name = "Materials",
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 5,
					Size = UDim2.fromScale(1, 0),

					create("UIGridLayout")({
						CellPadding = UDim2.fromOffset(12, 12),
						CellSize = UDim2.new(1 / 3, -8, 0, 58),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),

				secondary({
					Name = "Empty",
					LayoutOrder = 6,
					Size = UDim2.new(1, 0, 0, 20),
					Text = "No materials tracked yet",
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					Visible = false,
				}),
			}),

			-- Under the card: hint + close
			create("Frame")({
				Name = "Footer",
				BackgroundTransparency = 1,
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 0, 34),

				secondary({
					Name = "Hint",
					Position = UDim2.fromOffset(4, 0),
					Size = UDim2.new(1, -140, 1, 0),
					Text = "",
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				create("TextButton")({
					Name = "Close",
					AnchorPoint = Vector2.new(1, 0),
					AutoButtonColor = false,
					BorderSizePixel = 0,
					FontFace = REGULAR,
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromOffset(120, 34),
					Text = "Close",
					TextSize = 14,

					__dynamicKeys = {
						BackgroundColor3 = theme.Controls.View[1],
						TextColor3 = theme.Text.Primary[1],
						TextTransparency = theme.Text.Primary[2],
					},

					create("UICorner")({
						CornerRadius = UDim.new(0, 8),
					}),

					create("UIStroke")({
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

						__dynamicKeys = {
							Color = theme.Controls.ViewBorder[1],
							Transparency = theme.Controls.ViewBorder[2],
						},
					}),
				}),
			}),
		}),
	})

	local gui = structures.Gui.__instance :: ScreenGui
	local center = gui:FindFirstChild("Center") :: Frame
	local fit = center:FindFirstChild("Fit") :: UIScale
	local cardFrame = center:FindFirstChild("Card") :: Frame
	local header = cardFrame:FindFirstChild("Header") :: Frame
	local status = header:FindFirstChild("Status") :: Frame
	local timerRow = cardFrame:FindFirstChild("TimerRow") :: Frame
	local meta = timerRow:FindFirstChild("Meta") :: Frame
	local statsGrid = cardFrame:FindFirstChild("Stats") :: Frame
	local materialsHead = cardFrame:FindFirstChild("MaterialsHead") :: Frame
	local materialsGrid = cardFrame:FindFirstChild("Materials") :: Frame
	local footer = center:FindFirstChild("Footer") :: Frame
	local sweep = cardFrame:FindFirstChild("Divider"):FindFirstChild("Sweep") :: Frame

	structures.Center = center
	structures.Card = cardFrame
	structures.Logo = header:FindFirstChild("LogoTile"):FindFirstChild("Logo") :: ImageLabel
	structures.Title = header:FindFirstChild("Title") :: TextLabel
	structures.Subtitle = header:FindFirstChild("Subtitle") :: TextLabel
	structures.Status = status
	structures.StatusDot = status:FindFirstChild("Dot") :: Frame
	structures.StatusLabel = status:FindFirstChild("Label") :: TextLabel
	structures.Timer = timerRow:FindFirstChild("Timer") :: TextLabel
	structures.Started = meta:FindFirstChild("Started") :: TextLabel
	structures.Running = meta:FindFirstChild("Running") :: TextLabel
	structures.Stats = statsGrid
	structures.Materials = materialsGrid
	structures.MaterialsCount = materialsHead:FindFirstChild("Count") :: TextLabel
	structures.Empty = cardFrame:FindFirstChild("Empty") :: TextLabel
	structures.Hint = footer:FindFirstChild("Hint") :: TextLabel
	structures.Close = footer:FindFirstChild("Close") :: TextButton

	utility.FitText(structures.StatusLabel, 0, 18)
	utility.ProtectUI(gui)

	--// Formatting
	local function duration(seconds: number): string
		seconds = math.max(0, math.floor(seconds))

		local hours, minutes, secs = seconds // 3600, (seconds % 3600) // 60, seconds % 60

		if hours > 0 then
			return string.format("%dh %02dm", hours, minutes)
		elseif minutes > 0 then
			return string.format("%dm %02ds", minutes, secs)
		end

		return string.format("%ds", secs)
	end

	--// Stat tiles
	local function renderTile(name: string)
		local tile = tiles[name]

		if tile then
			local value, rate = store:Format(name)

			tile.Value.Text = value
			tile.Rate.Text = rate or ""
			tile.Rate.Visible = rate ~= nil
		end
	end

	local function makeTile(definition, order: number)
		local frame = tileFrame({
			Name = "Stat",
			LayoutOrder = order,
			Parent = statsGrid,

			create("UIPadding")({
				PaddingBottom = UDim.new(0, 12),
				PaddingLeft = UDim.new(0, 16),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 12),
			}),

			secondary({
				Name = "Caption",
				FontFace = SEMIBOLD,
				Size = UDim2.new(1, -22, 0, 14),
				Text = string.upper(definition.Label),
				TextSize = 11,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			create("ImageLabel")({
				Name = "Icon",
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(1, 0),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromOffset(14, 14),
				Visible = definition.Icon ~= nil,

				__dynamicKeys = {
					ImageColor3 = theme.Controls.Selection[1],
				},
			}),

			create("Frame")({
				Name = "Values",
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 28),

				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Bottom,
				}),

				primary({
					Name = "Value",
					AutomaticSize = Enum.AutomaticSize.X,
					FontFace = SEMIBOLD,
					Size = UDim2.fromOffset(0, 28),
					Text = "0",
					TextSize = 22,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				text({
					Name = "Rate",
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = 1,
					Size = UDim2.fromOffset(0, 18),
					Text = "",
					TextSize = 12,
					Visible = false,

					__dynamicKeys = {
						TextColor3 = theme.Controls.Status.Added[1],
					},
				}),
			}),
		}).__instance :: Frame

		if definition.Icon then
			icons.Apply(frame:FindFirstChild("Icon"), definition.Icon, nil, 14)
		end

		local values = frame:FindFirstChild("Values")

		tiles[definition.Name] = {
			Frame = frame,
			Value = values:FindFirstChild("Value") :: TextLabel,
			Rate = values:FindFirstChild("Rate") :: TextLabel,
		}

		renderTile(definition.Name)
	end

	local function rebuildTiles()
		for name, tile in pairs(tiles) do
			if not store.ByName[name] then
				tile.Frame:Destroy()
				tiles[name] = nil
			end
		end

		local count = 0

		for index, definition in ipairs(store.Stats) do
			if definition.Type ~= "Timer" then -- the big timer already shows the session
				count += 1

				if tiles[definition.Name] then
					tiles[definition.Name].Frame.LayoutOrder = index
				else
					makeTile(definition, index)
				end
			end
		end

		local columns = math.clamp(count, 1, 4)
		local grid = statsGrid:FindFirstChildOfClass("UIGridLayout")

		grid.CellSize = UDim2.new(1 / columns, -math.ceil(12 * (columns - 1) / columns), 0, 74)
		statsGrid.Visible = count > 0
	end

	--// Materials
	local function paintGain(pill: Frame, labelObj: TextLabel, gain: number)
		labelObj.Text = (gain > 0 and "+" or "") .. Store.FormatNumber(gain, "short")

		local added = theme.Controls.Status.Added[1].Value
		local removed = theme.Controls.Status.Removed[1].Value

		if gain > 0 then
			pill.BackgroundColor3 = added
			pill.BackgroundTransparency = 0.84
			labelObj.TextColor3 = added
			labelObj.TextTransparency = 0
		elseif gain < 0 then
			pill.BackgroundColor3 = removed
			pill.BackgroundTransparency = 0.84
			labelObj.TextColor3 = removed
			labelObj.TextTransparency = 0
		else
			pill.BackgroundColor3 = theme.Controls.Card.Hover[1].Value
			pill.BackgroundTransparency = theme.Controls.Card.Hover[2].Value
			labelObj.TextColor3 = theme.Text.Secondary[1].Value
			labelObj.TextTransparency = theme.Text.Secondary[2].Value
		end
	end

	local function keyOf(material): string
		return tostring(material.Name) .. "|" .. tostring(material.Icon)
	end

	local function refreshMaterials()
		-- Same materials in the same order: only the numbers change (no flicker / rebuild)
		local same = #materials == #materialRefs and #materials > 0

		if same then
			for index, material in ipairs(materials) do
				if materialRefs[index].Key ~= keyOf(material) then
					same = false
					break
				end
			end
		end

		if same then
			for index, material in ipairs(materials) do
				local refs = materialRefs[index]

				refs.Count.Text = Store.FormatNumber(tonumber(material.Count) or 0, "comma") .. " owned"
				paintGain(refs.Pill, refs.Gain, tonumber(material.Gain) or 0)
			end

			return
		end

		for _, row in ipairs(materialRows) do
			row:Destroy()
		end

		table.clear(materialRows)
		table.clear(materialRefs)

		for index, material in ipairs(materials) do
			local frame = tileFrame({
				Name = "Material",
				LayoutOrder = index,
				Parent = materialsGrid,

				create("UIPadding")({
					PaddingBottom = UDim.new(0, 10),
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
				}),

				create("Frame")({
					Name = "IconTile",
					AnchorPoint = Vector2.new(0, 0.5),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromOffset(38, 38),

					__dynamicKeys = {
						BackgroundColor3 = theme.Controls.Background[1],
					},

					create("UICorner")({
						CornerRadius = UDim.new(0, 7),
					}),

					create("ImageLabel")({
						Name = "Icon",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromOffset(28, 28),
					}),
				}),

				primary({
					Name = "Name",
					Position = UDim2.fromOffset(48, 1),
					Size = UDim2.new(1, -108, 0, 18),
					Text = tostring(material.Name or "Item"),
					TextSize = 13,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				secondary({
					Name = "Count",
					Position = UDim2.fromOffset(48, 21),
					Size = UDim2.new(1, -108, 0, 16),
					Text = "",
					TextSize = 11,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				create("Frame")({
					Name = "Pill",
					AnchorPoint = Vector2.new(1, 0.5),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(1, 0.5),
					Size = UDim2.fromOffset(0, 22),
					AutomaticSize = Enum.AutomaticSize.X,

					create("UICorner")({
						CornerRadius = UDim.new(1, 0),
					}),

					text({
						Name = "Gain",
						Size = UDim2.fromOffset(0, 22),
						Text = "",
						TextSize = 12,
					}),
				}),
			}).__instance :: Frame

			local iconImage = frame:FindFirstChild("IconTile"):FindFirstChild("Icon") :: ImageLabel
			local icon = material.Icon or properties.Icon

			if icon ~= nil then
				icons.Apply(iconImage, icon, nil, 28)
			end

			local pill = frame:FindFirstChild("Pill") :: Frame
			local gainLabel = pill:FindFirstChild("Gain") :: TextLabel

			utility.FitText(gainLabel, 8, 22)

			local refs = {
				Key = keyOf(material),
				Count = frame:FindFirstChild("Count") :: TextLabel,
				Pill = pill,
				Gain = gainLabel,
			}

			refs.Count.Text = Store.FormatNumber(tonumber(material.Count) or 0, "comma") .. " owned"
			paintGain(pill, gainLabel, tonumber(material.Gain) or 0)

			materialRefs[index] = refs
			table.insert(materialRows, frame)
		end

		structures.Empty.Visible = #materials == 0
		materialsGrid.Visible = #materials > 0
		structures.MaterialsCount.Text = #materials > 0 and (#materials .. " tracked") or ""
	end

	--// Status
	local function paintStatus()
		local color = theme.Controls.Status[statusKind]

		structures.StatusDot.BackgroundColor3 = typeof(properties.StatusColor) == "Color3" and properties.StatusColor
			or (color and color[1].Value)
			or theme.Controls.Status.Added[1].Value
	end

	--// Fit the card on small screens (phones)
	local function fitToScreen()
		local camera = workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
		local height = math.max(center.AbsoluteSize.Y / math.max(fit.Scale, 0.01), 560)

		fit.Scale = math.clamp(math.min((viewport.X - 48) / CARD_WIDTH, (viewport.Y - 48) / height), 0.4, 1)
	end

	--// 3D rendering off while the opaque screen is up
	local function set3D(enabled: boolean)
		if properties.Disable3D == false then
			return
		end

		if enabled and typeof(properties.Keep3DOff) == "function" then
			local ok, keep = pcall(properties.Keep3DOff)

			if ok and keep then
				return
			end
		end

		pcall(function()
			runService:Set3dRenderingEnabled(enabled)
		end)
	end

	local sweepTween = tweenService:Create(
		sweep,
		TweenInfo.new(2.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 0.8),
		{ Position = UDim2.fromScale(1, 0) }
	)

	local function renderTimer()
		local elapsed = os.clock() - sessionStart

		structures.Timer.Text = Store.Clock(elapsed)
		structures.Started.Text = "Started  " .. tostring(startedAt)
		structures.Running.Text = "Running  " .. duration(elapsed)
	end

	local function setVisible(value: boolean)
		value = value == true

		if value == shown then
			return
		end

		shown = value
		gui.Enabled = value

		if value then
			renderTimer()
			fitToScreen()
			task.defer(fitToScreen)
			sweepTween:Play()
			set3D(false)
		else
			sweepTween:Pause()
			set3D(true)
		end

		if properties.VisibleChanged then
			task.spawn(properties.VisibleChanged, object, value)
		end
	end

	--// Live updates
	local alive = true

	local disconnect = store:OnChanged(function(name)
		if name and store.ByName[name] and not tiles[name] then
			rebuildTiles()
			return
		end

		if name then
			renderTile(name)
		else
			for tileName in pairs(tiles) do
				renderTile(tileName)
			end
		end
	end)

	task.spawn(function()
		while alive do
			if shown then
				renderTimer()
			end

			task.wait(1)
		end
	end)

	center:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		if shown then
			fitToScreen()
		end
	end)

	pcall(function()
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			if shown then
				fitToScreen()
			end
		end)
	end)

	structures.Close.MouseButton1Click:Connect(function()
		setVisible(false)
	end)

	local function repaint()
		paintStatus()

		for index, material in ipairs(materials) do
			local refs = materialRefs[index]

			if refs then
				paintGain(refs.Pill, refs.Gain, tonumber(material.Gain) or 0)
			end
		end
	end

	-- Hand-painted parts follow theme / accent changes
	theme.Controls.Status.Added[1]:Connect(repaint)
	theme.Controls.Background[1]:Connect(repaint)
	theme.Text.Secondary[1]:Connect(repaint)

	local function destroy()
		if not alive then
			return
		end

		alive = false

		if shown then
			set3D(true)
		end

		shown = false
		disconnect()
		store:Destroy()
		sweepTween:Cancel()
		gui:Destroy()
	end

	-- Goes away (and turns 3D back on) with the app / window unload
	local root = utility.OverlayRoot(self)

	if root then
		root.Destroying:Connect(destroy)
	end

	--// Component
	object = binder.Wrap(properties, {
		Title = function(value: string)
			structures.Title.Text = tostring(value or "")
		end,
		Subtitle = function(value: string?)
			structures.Subtitle.Text = tostring(value or "")
		end,
		Icon = function(value)
			local applied = icons.Apply(structures.Logo, value or "chart-column", nil, 30)
			local isGlyph = value == nil or icons.IsGlyph(value)

			customLogo = not isGlyph

			structures.Logo.ImageColor3 = isGlyph and theme.Controls.Selection[1].Value or Color3.new(1, 1, 1)
			structures.Logo.Size = isGlyph and UDim2.fromOffset(28, 28) or UDim2.fromOffset(38, 38)

			return applied
		end,
		Status = function(value: string?)
			structures.Status.Visible = value ~= nil and value ~= ""
			structures.StatusLabel.Text = tostring(value or "")
			paintStatus()
		end,
		StatusKind = function(value: string?)
			statusKind = (value and theme.Controls.Status[value]) and value or "Added"
			paintStatus()
		end,
		StatusColor = function(value: Color3?)
			properties.StatusColor = value
			paintStatus()
		end,
		Footer = function(value: string?)
			structures.Hint.Text = tostring(value or "")
		end,
		Materials = function(value)
			materials = typeof(value) == "table" and value or {}
			refreshMaterials()
		end,
		Visible = function(value: boolean)
			setVisible(value)
		end,
		-- The component wrapper copies every constructor (Toggle, Label...) onto returned
		-- objects; ignore that so farmStats:Toggle() stays show / hide.
		Toggle = function() end,
	}, structures.Center, { "Visible", "Toggle" })

	object.Type = "FarmStats"
	object.Theme = theme
	object.Structures = structures
	object.Store = store

	object.Show = function()
		setVisible(true)
	end
	object.Hide = function()
		setVisible(false)
	end
	object.SetVisible = function(_, value: boolean)
		setVisible(value)
	end
	object.IsVisible = function()
		return shown
	end
	properties.Toggle = function()
		setVisible(not shown)
	end
	object.Set = function(_, name: string, value)
		store:Set(tostring(name), value)
	end
	object.SetStats = function(_, values)
		for name, value in pairs(values or {}) do
			store:Set(tostring(name), value)
		end
	end
	object.Get = function(_, name: string)
		return store:Get(tostring(name))
	end
	object.Increment = function(_, name: string, amount: number?)
		store:Increment(tostring(name), amount)
	end
	object.Define = function(_, definition)
		return store:Define(definition)
	end
	object.SetMaterials = function(_, list)
		object.Materials = list or {}
	end
	object.UpdateMaterial = function(_, name: string, count: number?, gain: number?, icon)
		local found = nil

		for _, material in ipairs(materials) do
			if material.Name == name then
				found = material
				break
			end
		end

		if found then
			found.Count = count ~= nil and count or found.Count
			found.Gain = gain ~= nil and gain or found.Gain
			found.Icon = icon ~= nil and icon or found.Icon
		else
			table.insert(materials, { Name = name, Count = count or 0, Gain = gain or 0, Icon = icon })
		end

		properties.Materials = materials
		refreshMaterials()
	end
	object.SetStatus = function(_, value: string?, kind)
		if typeof(kind) == "Color3" then
			object.StatusColor = kind
		else
			properties.StatusColor = nil
			object.StatusKind = kind or "Added"
		end

		object.Status = value
	end
	object.Reset = function(_, name: string?)
		store:Reset(name and tostring(name) or nil)

		if name == nil then
			sessionStart = os.clock()
			startedAt = os.date("%H:%M")
			renderTimer()
		end
	end
	object.ResetSession = object.Reset
	object.Destroy = function()
		destroy()
	end

	properties.Status = properties.Status or "Online"
	properties.Footer = properties.Footer or "The script keeps running behind this screen"
	properties.Materials = properties.Materials or {}

	local startVisible = properties.Visible == true
	properties.Visible = nil

	binder.Apply(properties, object)

	if properties.Icon == nil then
		object.Icon = nil -- default chart icon
	end

	rebuildTiles()
	refreshMaterials()

	if startVisible then
		setVisible(true)
	end

	return object
end
