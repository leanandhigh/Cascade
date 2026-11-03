-- We uh
-- We dont talk about this..

local types = require("@types")

return function(self, properties: types.WindowProperties): types.Window
	--// Imports
	local effects = require("@effects")
	local services = require("@modules/services")
	local creator = require("@modules/creator")
	local binder = require("@modules/binder")

	local titleBar, addToHistory = require("@structures/Titlebar")(self)
	local resizeHandler = require("@modules/resizeHandler")
	local popover = require("@modules/popover")
	local symbols = require("@modules/symbols")
	local profileStructure = require("@structures/Profile")(self)
	local configModule = require("@modules/config")

	--// References
	local create = creator.Create

	local userInputService = services.UserInputService
	local tweenService = services.TweenService
	local players = services.Players

	--// Variables
	local parent = self.__container or self.__instance or self
	local window = create("Frame")({
		Name = "Window",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Parent = parent,
	}).__instance
	local originalSize
	local originalPosition
	local originalPosition2
	local minimizing
	local dragging
	local resizeClient
	local structures = {}

	--// UI
	properties = properties or {}

	properties.Size = properties.Size or UDim2.fromOffset(850, 530)
	properties.Maximized = properties.Maximized == true
	properties.Minimized = properties.Minimized == true
	properties.Searching = properties.Searching ~= false
	properties.Resizable = properties.Resizable ~= false
	properties.Draggable = properties.Draggable ~= false
	properties.CanExit = properties.CanExit ~= false
	properties.CanMinimize = properties.CanMinimize ~= false
	properties.CanZoom = properties.CanZoom ~= false
	properties.Resizable = properties.Resizable ~= false
	properties.Dropshadow = properties.Dropshadow ~= false
	properties.UIBlur = properties.UIBlur ~= false
	properties.Title = properties.Title or "Title"

	-- macOS traffic-light dots are hidden by default; the sidebar moves up into their space
	properties.WindowControls = properties.WindowControls == true
	properties.CanUnload = properties.CanUnload ~= false

	-- User profile (bottom-left of the sidebar)
	properties.UserProfile = properties.UserProfile ~= false
	properties.CensorName = properties.CensorName == true
	properties.HideAvatar = properties.HideAvatar == true
	properties.ProfileSubtitle = properties.ProfileSubtitle or "Account"

	-- Key duration (seconds from now) is converted to an expiry timestamp
	if properties.KeyDuration then
		properties.KeyExpires = os.time() + properties.KeyDuration
	end

	-- Language picker (left of the search field)
	if properties.Languages and not properties.Language then
		properties.Language = properties.Languages[1]
	end

	local windowControls, windowControlsCKeys = require("@structures/WindowControls")(self, properties)

	structures.Body = binder.Apply(
		properties,
		create("Frame")({
			Name = "Body",
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Parent = window,

			__dynamicKeys = {
				BackgroundColor3 = self.Theme.Controls.Sidebar[1],
				BackgroundTransparency = self.Theme.Controls.Sidebar[2],
			},

			__contextKeys = {
				BackgroundTransparency = function()
					return properties.UIBlur and self.Theme.Controls.Sidebar[2].Value or 0
				end,
			},

			create("UICorner")({
				Name = "UICorner",
				CornerRadius = UDim.new(0, 10),
			}),

			create("UIListLayout")({
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			create("Frame")({
				Name = "Sidebar",
				BackgroundColor3 = Color3.fromRGB(234, 234, 234),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 200, 1, 0),
				ClipsDescendants = true,

				create("UIPadding")({
					Name = "UIPadding",
				}),

				create("Frame")({
					Name = "Margins",
					BackgroundColor3 = Color3.fromRGB(234, 234, 234),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 200, 1, 0),
					create("Folder")({
						Name = "LayoutIgnore",

						create("Frame")({
							Name = "Shadow",
							AnchorPoint = Vector2.new(1, 0),
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Position = UDim2.new(1, 2, 0, 0),
							Size = UDim2.new(0, 5, 1, 0),
							ZIndex = 0,
							__dynamicKeys = {
								BackgroundColor3 = self.Theme.Controls.Separator.Shadow[1],
								BackgroundTransparency = self.Theme.Controls.Separator.Shadow[2],
							},

							create("UIGradient")({
								Name = "UIGradient",
								Transparency = NumberSequence.new({
									NumberSequenceKeypoint.new(0, 1),
									NumberSequenceKeypoint.new(1, 0),
								}),
							}),
						}),
					}),

					create("UIPadding")({
						Name = "UIPadding",
						PaddingRight = UDim.new(0, 2),
					}),

					create("Frame")({
						Name = "Toolbar",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 52),
					}),

					create("ScrollingFrame")({
						Name = "SidebarList",
						AutomaticCanvasSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						CanvasSize = UDim2.new(),
						Position = UDim2.fromOffset(0, 52),
						ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
						ScrollBarImageTransparency = 0.7,
						ScrollBarThickness = 6,
						Size = UDim2.new(1, 0, 1, -52),

						__dynamicKeys = {
							ScrollBarImageColor3 = self.Theme.Controls.ScrollBar[1],
							ScrollBarImageTransparency = self.Theme.Controls.ScrollBar[2],
						},

						create("UIListLayout")({
							Name = "UIListLayout",
							Padding = UDim.new(0, 9),
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
						}),

						create("UIPadding")({
							Name = "UIPadding",
							PaddingLeft = UDim.new(0, 10),
							PaddingRight = UDim.new(0, 10),
							PaddingBottom = UDim.new(0, 10),
						}),
					}),
				}),
			}),

			create("Frame")({
				Name = "Separator",
				AnchorPoint = Vector2.new(1, 0),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 1, 1, 0),
				__dynamicKeys = {
					BackgroundColor3 = self.Theme.Controls.Separator.Background[1],
					BackgroundTransparency = self.Theme.Controls.Separator.Background[2],
				},
			}),

			create("Frame")({
				Name = "ContentBody",
				AnchorPoint = Vector2.new(1, 0),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 2,
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(1, -201, 1, 0),

				__dynamicKeys = {
					BackgroundColor3 = self.Theme.Controls.Background[1],
					BackgroundTransparency = self.Theme.Controls.Background[2],
				},

				create("UICorner")({
					Name = "UICorner",
					CornerRadius = UDim.new(0, 10),
				}),

				create("Frame")({
					Name = "Content",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(255, 199, 199),
					BorderMode = Enum.BorderMode.Inset,
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Position = UDim2.fromOffset(0, 52),
					Size = UDim2.new(1, 0, 1, -52),

					create("UIPadding")({
						Name = "Margins",
						PaddingBottom = UDim.new(0, 3),
						PaddingLeft = UDim.new(0, 3),
						PaddingRight = UDim.new(0, 3),
						PaddingTop = UDim.new(0, 3),
					}),
				}),

				create("Frame")({
					Name = "CornerClip",
					AnchorPoint = Vector2.new(0, 1),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromOffset(10, 10),
					ZIndex = -1,

					__dynamicKeys = {
						BackgroundColor3 = self.Theme.Controls.Background[1],
					},
				}),
			}),

			create("Folder")({
				Name = "LayoutIgnore",

				create("TextButton")({
					Name = "TopArea",
					AutoButtonColor = false,
					Active = false,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 52),
					ZIndex = 0,
					Text = "",
					Modal = false,
				}),

				create("ImageLabel")({
					Name = "Dropshadow",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Image = "rbxassetid://138260268144845",
					ImageTransparency = 0.65,
					Interactable = false,
					Position = UDim2.new(0.5, 0, 0.5, 3),
					ScaleType = Enum.ScaleType.Slice,
					Size = UDim2.new(1, 24, 1, 24),
					SliceCenter = Rect.new(28, 26, 96, 94),
					ZIndex = 0,
				}),
			}),
		})
	) :: Frame

	--// Initialize
	structures.Scale = create("UIScale")({
		Parent = window,
	})
	structures.Cornering = structures.Body:FindFirstChild("UICorner") :: UICorner
	structures.LayoutIgnore = structures.Body:FindFirstChild("LayoutIgnore") :: Folder
	structures.Dropshadow = structures.LayoutIgnore:FindFirstChild("Dropshadow") :: ImageLabel
	structures.Separator = structures.Body:FindFirstChild("Separator") :: Frame
	structures.SidebarMargins = structures.Body:FindFirstChild("Sidebar")
	structures.Sidebar = structures.SidebarMargins:FindFirstChild("Margins") :: Frame
	structures.SidebarList = structures.Sidebar:FindFirstChild("SidebarList") :: Frame
	structures.Toolbar = structures.Sidebar:FindFirstChild("Toolbar") :: Frame
	structures.ContentBody = structures.Body:FindFirstChild("ContentBody") :: Frame
	structures.Content = structures.ContentBody:FindFirstChild("Content") :: Frame
	structures.CornerClip = structures.ContentBody:FindFirstChild("CornerClip") :: Frame

	structures.Titlebar = titleBar
	structures.Titlebar.Body.Parent = structures.ContentBody

	structures.WindowControls = windowControls
	structures.WindowControls.Body.Parent = structures.Toolbar

	structures.Profile = profileStructure
	structures.Profile.Body.Parent = structures.Sidebar

	-- Brand header (logo + name) at the top of the sidebar, same height as the titlebar
	structures.Brand = create("Frame")({
		Name = "Brand",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 52),
		Visible = false,
		Parent = structures.Sidebar,

		create("UIPadding")({
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 12),
		}),

		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),

		create("Frame")({
			Name = "LogoHolder",
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(30, 30),

			create("UICorner")({
				CornerRadius = UDim.new(0, 8),
			}),

			create("ImageLabel")({
				Name = "Logo",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(1, 1),

				create("UICorner")({
					CornerRadius = UDim.new(0, 8),
				}),
			}),
		}),

		create("Frame")({
			Name = "Texts",
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Size = UDim2.new(1, -40, 1, 0),

			create("UIListLayout")({
				Padding = UDim.new(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			create("TextLabel")({
				Name = "Name",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				Size = UDim2.new(1, 0, 0, 18),
				TextSize = 16,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,

				__dynamicKeys = {
					TextColor3 = self.Theme.Text.Primary[1],
					TextTransparency = self.Theme.Text.Primary[2],
				},
			}),

			create("TextLabel")({
				Name = "Subtitle",
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxassetid://12187365364"),
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 14),
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				Visible = false,

				__dynamicKeys = {
					TextColor3 = self.Theme.Text.Secondary[1],
					TextTransparency = self.Theme.Text.Secondary[2],
				},
			}),
		}),
	})

	local brandBody = structures.Brand.__instance
	local brandLogoHolder = brandBody:FindFirstChild("LogoHolder")
	local brandLogo = brandLogoHolder:FindFirstChild("Logo")
	local brandTexts = brandBody:FindFirstChild("Texts")
	local brandName = brandTexts:FindFirstChild("Name")
	local brandSubtitle = brandTexts:FindFirstChild("Subtitle")

	structures.ProfileMenu = popover.new(self, { Name = "ProfileMenu", Width = 180 })

	local PROFILE_HEIGHT = 62
	local unloaded = false

	local function toolbarHeight(): number
		return properties.WindowControls and 52 or 0
	end

	local function hasBrand(): boolean
		return properties.Logo ~= nil or properties.Brand ~= nil
	end

	local function layoutSidebar()
		local controls = toolbarHeight()
		local top = controls + (hasBrand() and 52 or 0)

		structures.Brand.Visible = hasBrand()
		structures.Brand.Position = UDim2.fromOffset(0, controls)
		local bottom = properties.UserProfile and PROFILE_HEIGHT or 0
		local padding = structures.SidebarList:FindFirstChild("UIPadding")

		structures.Toolbar.Visible = properties.WindowControls
		structures.SidebarList.Position = UDim2.fromOffset(0, top)
		structures.SidebarList.Size = UDim2.new(1, 0, 1, -(top + bottom))

		if padding then
			padding.PaddingTop = UDim.new(0, (properties.WindowControls or hasBrand()) and 4 or 12)
		end
	end

	local localPlayer = players.LocalPlayer
	local keyExpiredFired = false
	local object

	--// Profile helpers
	local function censor(name: string): string
		local length = utf8.len(name) or #name

		if length <= 2 then
			return string.rep("*", length)
		end

		local first = utf8.offset(name, 2) and string.sub(name, 1, utf8.offset(name, 2) - 1) or string.sub(name, 1, 1)
		local lastStart = utf8.offset(name, -1) or #name

		return first .. string.rep("*", math.min(length - 2, 6)) .. string.sub(name, lastStart)
	end

	local function formatDuration(seconds: number): string
		seconds = math.max(0, math.floor(seconds))

		local days = seconds // 86400
		local hours = (seconds % 86400) // 3600
		local minutes = (seconds % 3600) // 60
		local secs = seconds % 60

		if days > 0 then
			return string.format("%dd %dh %dm", days, hours, minutes)
		elseif hours > 0 then
			return string.format("%dh %dm %ds", hours, minutes, secs)
		end

		return string.format("%dm %ds", minutes, secs)
	end

	local function isLifetime(value): boolean
		return value == true
			or value == math.huge
			or (typeof(value) == "string" and string.lower(value) == "lifetime")
	end

	local function displayName(): string
		local name = properties.ProfileName or (localPlayer and localPlayer.DisplayName) or "Player"

		return properties.CensorName and censor(name) or name
	end

	local function refreshName()
		structures.Profile.DisplayName.Text = displayName()
	end

	local function refreshAvatar()
		local image = properties.ProfileImage

		if not image and localPlayer then
			image = "rbxthumb://type=AvatarHeadShot&id=" .. localPlayer.UserId .. "&w=150&h=150"
		end

		structures.Profile.Avatar.Image = image or ""
		structures.Profile.Avatar.Visible = not properties.HideAvatar and image ~= nil
		structures.Profile.Placeholder.Visible = not structures.Profile.Avatar.Visible
	end

	-- Returns the key / account text and its colour pair (shared by the profile card and Dashboard)
	local function keyStatus()
		local theme = self.Theme
		local expires = properties.KeyExpires
		local text, color = properties.ProfileSubtitle, theme.Text.Secondary

		if expires ~= nil and expires ~= false then
			if isLifetime(expires) then
				text, color = "Key: Lifetime", theme.Controls.Status.Added
			elseif typeof(expires) == "number" then
				local remaining = expires - os.time()

				if remaining <= 0 then
					text, color = "Key expired", theme.Controls.Status.Removed

					if not keyExpiredFired then
						keyExpiredFired = true

						if properties.KeyExpired then
							task.spawn(properties.KeyExpired, object)
						end
					end
				else
					text = "Key: " .. formatDuration(remaining)
					color = remaining < 86400 and theme.Controls.Status.Changed or theme.Text.Secondary
				end
			elseif typeof(expires) == "string" then
				text = "Key: " .. expires
			end
		end

		return text, color
	end

	local function refreshSubtitle()
		local label = structures.Profile.Subtitle
		local text, color = keyStatus()

		label.Text = text
		label.TextColor3 = color[1].Value
		label.TextTransparency = color[2].Value
	end

	--// Profile menu
	local censorItem = structures.ProfileMenu:AddItem({
		Title = "Censor Name",
		Icon = "eye-off",
		IconFallback = symbols.eyeSlash,
		Checked = properties.CensorName,
		Changed = function(value: boolean)
			object.CensorName = value
		end,
	})

	local avatarItem = structures.ProfileMenu:AddItem({
		Title = "Hide Avatar",
		Icon = "user-x",
		IconFallback = symbols.personCropCircle,
		Checked = properties.HideAvatar,
		Changed = function(value: boolean)
			object.HideAvatar = value
		end,
	})

	structures.Profile.Settings.MouseButton1Click:Connect(function()
		structures.ProfileMenu:Toggle(structures.Profile.Settings)
	end)

	structures.Body.Destroying:Connect(function()
		structures.ProfileMenu:Destroy()
	end)

	structures.Titlebar.LanguagePicker.OnSelected(function(language: string)
		object.Language = language
	end)

	-- Live key countdown + keeps state colors in sync with theme changes
	task.defer(function()
		while structures.Body.Parent do
			refreshSubtitle()
			task.wait(1)
		end
	end)

	originalSize = structures.Body.Size
	originalPosition = structures.Body.Position

	local bindings = {
		Title = function(value: string)
			structures.Titlebar.Title.Visible = value and true or false

			if value then
				structures.Titlebar.Title.Text = value
			end
		end,
		Subtitle = function(value: string)
			structures.Titlebar.Subtitle.Visible = value and true or false

			if value then
				structures.Titlebar.Subtitle.Text = value
			end
		end,
		Searching = function(value: boolean)
			structures.Titlebar.SearchField.Body.Parent = value and structures.Titlebar.Trailing or nil
			structures.Titlebar.SearchField.Body.Visible = value
		end,
		Draggable = function(value: boolean)
			dragging = not value and false
		end,
		Resizable = function(value: boolean)
			if resizeClient and not properties.Maximized then
				resizeClient.SetEnabled(value)
			end
		end,
		Minimized = function(value: boolean?, tween: boolean?)
			local useTween = tween ~= false

			if value and not minimizing then
				originalPosition2 = structures.Body.Position

				if structures["BlurModel"] then
					structures["BlurModel"].SetVisibility(false)
				end
			end

			local tweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local bodyTarget = {
				Position = value and UDim2.new(0.5, 0, 0.5, structures.Body.AbsoluteSize.Y * 2) or originalPosition2,
			}
			local scaleTarget = { Scale = value and 0 or 1 }

			if useTween then
				minimizing = true
				tweenService:Create(structures.Body.__instance, tweenInfo, bodyTarget):Play()

				local scaleTween: Tween = tweenService:Create(structures.Scale.__instance, tweenInfo, scaleTarget)

				scaleTween:Play()
				scaleTween.Completed:Once(function()
					minimizing = false

					if structures["BlurModel"] and not properties.Minimized then
						structures["BlurModel"].SetVisibility(true)
					end
				end)
			else
				structures.Body.Position = bodyTarget.Position
				structures.Scale.Scale = scaleTarget.Scale

				if value and structures["BlurModel"] then
					structures["BlurModel"].SetVisibility(false)
				end
			end
		end,
		Maximized = function(value: boolean?, tween: boolean?)
			tween = tween ~= false

			if value then
				originalSize = structures.Body.Size
				originalPosition = structures.Body.Position
				resizeClient.SetEnabled(false)
			else
				dragging = false
			end

			local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
			local bodyTarget = {
				Size = value and UDim2.fromScale(1, 1) or originalSize,
				Position = value and UDim2.fromScale(0.5, 0.5) or originalPosition,
			}
			local cornerTarget = { CornerRadius = value and UDim.new(0, 0) or UDim.new(0, 10) }

			if tween then
				tweenService:Create(structures.Body.__instance, tweenInfo, bodyTarget):Play()
				tweenService:Create(structures.Cornering, tweenInfo, cornerTarget):Play()
			else
				structures.Body.Size = bodyTarget.Size
				structures.Body.Position = bodyTarget.Position
				structures.Cornering.CornerRadius = cornerTarget.CornerRadius
			end

			if not value then
				resizeClient.SetEnabled(properties.Resizable)
			end
		end,
		Dropshadow = function(value: boolean)
			structures.Dropshadow.Visible = value
		end,
		UIBlur = function(value: boolean)
			if structures["BlurModel"] then
				structures["BlurModel"].Model:Destroy()
				structures["BlurModel"] = nil
			end

			structures.Body.BackgroundTransparency = value and self.Theme.Controls.Sidebar[2].Value or 0

			if value and not properties.Minimized then
				structures.BlurModel = effects.UIBlur(structures.Body)
			end
		end,
		CanExit = function(value: boolean)
			properties.CanExit = value

			structures.WindowControls.Exit.ImageColor3 = windowControlsCKeys.Exit.ImageColor3()
			structures.WindowControls.Exit.ImageTransparency = windowControlsCKeys.Exit.ImageTransparency()

			structures.WindowControls.Exit.Active = value
		end,
		CanMinimize = function(value: boolean)
			properties.CanMinimize = value

			structures.WindowControls.Minimize.ImageColor3 = windowControlsCKeys.Minimize.ImageColor3()
			structures.WindowControls.Minimize.ImageTransparency = windowControlsCKeys.Minimize.ImageTransparency()

			structures.WindowControls.Minimize.Active = value
		end,
		CanZoom = function(value: boolean)
			properties.CanZoom = value

			structures.WindowControls.Zoom.ImageColor3 = windowControlsCKeys.Zoom.ImageColor3()
			structures.WindowControls.Zoom.ImageTransparency = windowControlsCKeys.Zoom.ImageTransparency()

			structures.WindowControls.Zoom.Active = value
		end,
	}
	-- Profile bindings
	bindings.UserProfile = function(value: boolean)
		properties.UserProfile = value
		structures.Profile.Body.Visible = value
		layoutSidebar()
	end
	bindings.WindowControls = function(value: boolean)
		properties.WindowControls = value
		layoutSidebar()
	end
	-- Branding (logo + name at the top of the sidebar)
	local function refreshBrand()
		local logo = properties.Logo
		local icon = logo ~= nil and require("@modules/icons").Get(logo)
		local isGlyph = icon and icon.ImageRectSize.X > 0

		brandLogoHolder.Visible = logo ~= nil

		if logo ~= nil then
			require("@modules/icons").Apply(brandLogo, logo)

			-- Lucide glyphs get an accent tile; your own logo image is shown as-is
			brandLogo.Size = isGlyph and UDim2.fromOffset(18, 18) or UDim2.fromScale(1, 1)
			brandLogo.ImageColor3 = isGlyph and self.Theme.Controls.Selection[1].Value or Color3.new(1, 1, 1)
			brandLogoHolder.BackgroundColor3 = self.Theme.Controls.Selection[1].Value
			brandLogoHolder.BackgroundTransparency = isGlyph and 0.85 or 1
		end

		brandName.Text = properties.Brand or properties.Title or ""
		brandSubtitle.Text = properties.BrandSubtitle or ""
		brandSubtitle.Visible = properties.BrandSubtitle ~= nil
		brandTexts.Size = UDim2.new(1, logo ~= nil and -40 or 0, 1, 0)

		layoutSidebar()
	end

	self.Theme.Controls.Selection[1]:Connect(function()
		task.defer(refreshBrand)
	end)

	-- Lucide may still be loading in the background; restyle the logo when it's ready
	require("@modules/icons").WhenReady(function()
		if properties.Logo ~= nil then
			refreshBrand()
		end
	end)

	bindings.Logo = function(value)
		properties.Logo = value
		refreshBrand()
	end
	bindings.Brand = function(value: string?)
		properties.Brand = value
		refreshBrand()
	end
	bindings.BrandSubtitle = function(value: string?)
		properties.BrandSubtitle = value
		refreshBrand()
	end

	bindings.CanUnload = function(value: boolean)
		structures.Titlebar.Unload.Visible = value
	end
	bindings.ProfileName = function(value: string?)
		properties.ProfileName = value
		refreshName()
	end
	bindings.ProfileSubtitle = function(value: string?)
		properties.ProfileSubtitle = value or "Account"
		refreshSubtitle()
	end
	bindings.ProfileImage = function(value: string?)
		properties.ProfileImage = value
		refreshAvatar()
	end
	bindings.CensorName = function(value: boolean)
		local changed = properties.CensorName ~= value

		properties.CensorName = value == true
		censorItem:Set(properties.CensorName, true)
		refreshName()

		if changed and properties.ProfileSettingChanged then
			task.spawn(properties.ProfileSettingChanged, object, "CensorName", properties.CensorName)
		end
	end
	bindings.HideAvatar = function(value: boolean)
		local changed = properties.HideAvatar ~= value

		properties.HideAvatar = value == true
		avatarItem:Set(properties.HideAvatar, true)
		refreshAvatar()

		if changed and properties.ProfileSettingChanged then
			task.spawn(properties.ProfileSettingChanged, object, "HideAvatar", properties.HideAvatar)
		end
	end
	bindings.ProfileOptions = function(options)
		if typeof(options) ~= "table" or #options == 0 then
			return
		end

		structures.ProfileMenu:AddSeparator()

		for _, option in ipairs(options) do
			structures.ProfileMenu:AddItem(option)
		end
	end

	-- Key duration bindings (paid scripts)
	bindings.KeyExpires = function(value)
		properties.KeyExpires = value
		keyExpiredFired = false
		refreshSubtitle()
	end
	bindings.KeyDuration = function(seconds: number?)
		bindings.KeyExpires(seconds and (os.time() + seconds) or nil)
	end

	-- Language bindings
	bindings.Languages = function(value: { string }?)
		properties.Languages = value
		structures.Titlebar.LanguagePicker.SetLanguages(value or {})
	end
	bindings.Language = function(value: string?)
		properties.Language = value
		structures.Titlebar.LanguagePicker.Select(value)

		if properties.LanguageChanged then
			task.spawn(properties.LanguageChanged, object, value)
		end
	end

	object = binder.Wrap(properties, bindings, structures.Body)

	object.Type = "Window"
	object.Theme = self.Theme
	object.Structures = structures
	object.Tabs = {}
	object.addToHistory = addToHistory(object)
	object.__container = structures.Content
	object.__window = object
	object.__app = self

	-- Titlebar shows the selected tab's title when TabTitles is on (default when a brand is set,
	-- since the brand header already shows the hub name)
	local function useTabTitles(): boolean
		if properties.TabTitles ~= nil then
			return properties.TabTitles == true
		end

		return properties.Logo ~= nil or properties.Brand ~= nil
	end

	object.__pageTitle = function(title: string?)
		if useTabTitles() and title then
			structures.Titlebar.Title.Visible = true
			structures.Titlebar.Title.Text = title
		end
	end

	-- Text + colour of the key status ("Key: 3d 4h 0m", "Key: Lifetime", "Account"...)
	object.KeyStatus = function()
		return keyStatus()
	end
	-- Player name as shown on the profile card (censored when CensorName is on)
	object.DisplayName = function()
		return displayName()
	end

	-- Unload: runs the dev's cleanup callback, then removes the whole UI (window, pill, overlays, menus)
	object.Unload = function()
		if unloaded then
			return
		end

		unloaded = true

		if properties.Unloaded then
			local ok, err = pcall(properties.Unloaded, object)

			if not ok then
				warn("[Cascade] Unloaded callback errored:", err)
			end
		end

		local root = structures.Body.__instance:FindFirstAncestorWhichIsA("ScreenGui")

		bindings.Minimized(true)

		task.delay(0.25, function()
			structures.ProfileMenu:Destroy()
			structures.Body:Destroy()

			if root and root.Name == "Cascade" then
				root:Destroy()
			end
		end)
	end

	-- Config manager (its UI is the ConfigManager groupbox in the Settings tab)
	if properties.Config ~= false then
		local options = typeof(properties.Config) == "table" and properties.Config or {}

		-- The UI for configs lives in the Settings tab (window:Settings() / tab:ConfigManager()),
		-- the manager itself is always available as window.Configs.
		object.Configs = configModule.new(options)

		if options.AutoLoad ~= false then
			task.defer(function()
				object.Configs:LoadDefault()
			end)
		end
	end

	do -- Resize handler
		resizeClient = resizeHandler(structures.Body.__instance, Vector2.new(350, 250))

		resizeClient.CreateClient()
	end

	do -- Sidebar button
		local toggled = true

		local function toggle()
			toggled = not toggled

			local marginsTargetSize = toggled and UDim.new(0, 0) or UDim.new(0, -200)
			local sidebarTargetSize = toggled and UDim2.new(0, 200, 1, 0) or UDim2.new(0, 0, 1, 0)
			local contentTargetSize = toggled and UDim2.new(1, -201, 1, 0) or UDim2.new(1, 0, 1, 0)
			local cornerLeftSize = toggled and UDim2.new(0, 10, 1, 0) or UDim2.new(0, 10, 0.5, 0)

			local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

			structures.Separator.Visible = toggled and true or false
			structures.CornerClip.Visible = toggled and true

			tweenService
				:Create(structures.ContentBody, tweenInfo, {
					Size = contentTargetSize,
				})
				:Play()

			tweenService
				:Create(structures.SidebarMargins:FindFirstChild("UIPadding"), tweenInfo, {
					PaddingLeft = marginsTargetSize,
				})
				:Play()

			local sidebarTween = tweenService:Create(structures.SidebarMargins, tweenInfo, {
				Size = sidebarTargetSize,
			})

			tweenService
				:Create(structures.Titlebar.CornerClipLeft, tweenInfo, {
					Size = cornerLeftSize,
				})
				:Play()

			sidebarTween:Play()

			if not toggled then
				sidebarTween.Completed:Connect(function()
					structures.CornerClip.Visible = false
				end)
			end
		end

		structures.Titlebar.SidebarButton.MouseButton1Click:Connect(toggle)
	end

	do -- Page searching
		local field = structures.Titlebar.SearchField.Field
		local pageCaches = {}

		local function toCache(page, descendants)
			local cache = {}

			for _, child in ipairs(descendants) do
				if child:IsA("GuiObject") then
					cache[child] = child.Visible
				end
			end

			pageCaches[page] = cache
		end

		local function fromCache(page, descendants)
			local cache = pageCaches[page]

			if not cache then
				return
			end

			for _, child in ipairs(descendants) do
				if child:IsA("GuiObject") then
					child.Visible = cache[child] ~= false
				end
			end
		end

		field:GetPropertyChangedSignal("Text"):Connect(function()
			local matches = {}
			local items = {}
			local page = structures.Content:FindFirstChildOfClass("ScrollingFrame")

			if not page then
				return
			end

			local descendants = page:GetDescendants()

			if not pageCaches[page] then
				toCache(page, descendants)
			end

			local query = field.Text:lower()

			if query == "" then
				fromCache(page, descendants)
				return
			end

			for _, child in ipairs(descendants) do
				if child:IsA("GuiObject") then
					local searchIndex = child:GetAttribute("SearchIndex")

					if typeof(searchIndex) == "string" and searchIndex:lower():find(query) then
						table.insert(matches, child)
					end
				end
			end

			for _, match in ipairs(matches) do
				items[match] = true

				local parent = match.Parent

				while parent and parent ~= page do
					if parent:IsA("GuiObject") then
						items[parent] = true
					end

					parent = parent.Parent
				end
			end

			for _, child in ipairs(descendants) do
				if child:IsA("GuiObject") then
					child.Visible = false
				end
			end

			for _, match in ipairs(matches) do
				match.Visible = true

				local parent = match.Parent

				while parent and parent ~= page do
					if parent:IsA("GuiObject") then
						parent.Visible = true
					end

					parent = parent.Parent
				end

				local cache = pageCaches[page]

				for _, descendant in ipairs(match:GetDescendants()) do
					if descendant:IsA("GuiObject") then
						local wasVisible = cache and cache[descendant]
						if wasVisible then
							descendant.Visible = true
						end
					end
				end
			end
		end)
	end

	do -- Window controls
		local wcBody = structures.WindowControls.Body
		local exit = wcBody:FindFirstChild("Exit") :: ImageButton
		local minimize = wcBody:FindFirstChild("Minimize") :: ImageButton
		local zoom = wcBody:FindFirstChild("Zoom") :: ImageButton

		local function rollOver()
			exit:FindFirstChild("Icon").Visible = properties.CanExit
					and wcBody.GuiState ~= Enum.GuiState.Hover
				or false
			minimize:FindFirstChild("Icon").Visible = properties.CanMinimize
					and wcBody.GuiState ~= Enum.GuiState.Hover
				or false
			zoom:FindFirstChild("Icon").Visible = properties.CanZoom
					and wcBody.GuiState ~= Enum.GuiState.Hover
				or false
		end

		zoom.MouseButton1Click:Connect(function()
			if not properties.CanZoom then
				return
			end
			properties.Maximized = not properties.Maximized
			bindings.Maximized(properties.Maximized, true)
		end)

		minimize.MouseButton1Click:Connect(function()
			if not properties.CanMinimize then
				return
			end
			properties.Minimized = not properties.Minimized
			bindings.Minimized(properties.Minimized, true)
		end)

		if self.Structures and self.Structures["WindowPill"] then
			local pill: ImageButton = self.Structures["WindowPill"]

			pill.MouseButton1Click:Connect(function()
				properties.Minimized = not properties.Minimized
				bindings.Minimized(properties.Minimized, true)
			end)
		end

		exit.MouseButton1Click:Connect(function()
			if not properties.CanExit then
				return
			end

			bindings.Minimized(true)
			task.delay(0.25, structures.Body.Destroy)
		end)

		structures.Titlebar.Unload.MouseButton1Click:Connect(function()
			if properties.CanUnload then
				object:Unload()
			end
		end)

		wcBody.MouseEnter:Connect(rollOver)
		wcBody.MouseLeave:Connect(rollOver)
	end

	do -- Window dragging
		local inputPos = nil
		local startPos = nil
		local connection = nil
		local boundingUi = structures.LayoutIgnore:FindFirstChild("TopArea")

		boundingUi.InputBegan:Connect(function(input)
			if
				(
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
				)
				and properties.Draggable
				and not properties.Maximized
			then
				dragging = true
				inputPos = input.Position
				startPos = structures.Body.Position

				if connection then
					connection:Disconnect()
				end

				connection = input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
					end
				end)
			end
		end)

		userInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			then
				if dragging then
					local delta = input.Position - inputPos
					local newPosition = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)

					structures.Body.Position = newPosition
				end
			end
		end)
	end

	binder.Apply(properties, object)

	-- Roblox sometimes lays out AutomaticSize frames wrong on first render. This used to resize
	-- every descendant twice in one frame (thousands of resizes + their listeners = lag spike on
	-- execute). Now: one cheap nudge of the window, then a single pass over only the auto-sized
	-- descendants, spread across frames.
	local function nudge()
		local body = structures.Body.__instance
		local original = body.Size

		body.Size = original + UDim2.fromOffset(1, 0)
		body.Size = original
	end

	local function recheck()
		local body = structures.Body.__instance

		if not body.Parent then
			return
		end

		local processed = 0

		for _, descendant in ipairs(body:GetDescendants()) do
			if descendant:IsA("GuiObject") and descendant.AutomaticSize ~= Enum.AutomaticSize.None then
				local original = descendant.Size

				descendant.Size = UDim2.fromOffset(0, 0)
				descendant.Size = original

				processed += 1

				if processed % 150 == 0 then
					task.wait()

					if not body.Parent then
						return
					end
				end
			end
		end
	end

	task.defer(nudge)
	task.delay(1, recheck)

	return object
end
