-- Base Types

export type Instance = {
	Name: string?,
	Parent: Instance?,
	Archivable: boolean?,
	ClassName: string?,

	Clone: ((self: Instance) -> Instance)?,
	Destroy: ((self: Instance) -> ())?,
	FindFirstAncestor: ((self: Instance, name: string) -> Instance?)?,
	FindFirstAncestorWhichIsA: ((self: Instance, className: string) -> Instance?)?,
	FindFirstAncestorOfClass: ((self: Instance, className: string) -> Instance?)?,
	FindFirstChild: ((self: Instance, name: string, recursive: boolean?) -> Instance?)?,
	FindFirstChildWhichIsA: ((self: Instance, className: string, recursive: boolean?) -> Instance?)?,
	FindFirstChildOfClass: ((self: Instance, className: string, recursive: boolean?) -> Instance?)?,
	GetAttribute: ((self: Instance, attribute: string) -> any)?,
	GetAttributes: ((self: Instance) -> { [string]: any })?,
	GetChildren: ((self: Instance) -> { Instance })?,
	GetDescendants: ((self: Instance) -> { Instance })?,
	HasTag: ((self: Instance, tag: string) -> boolean)?,
	IsA: ((self: Instance, className: string) -> boolean)?,
	IsAncestorOf: ((self: Instance, descendant: Instance) -> boolean)?,
	IsDescendantOf: ((self: Instance, ancestor: Instance) -> boolean)?,
	WaitForChild: ((self: Instance, childName: string, timeOut: number?) -> Instance)?,

	AncestryChanged: ((self: Instance, handler: (child: Instance, parent: Instance?) -> ()) -> RBXScriptConnection)?,
	AttributeChanged: ((self: Instance, handler: (attribute: string) -> ()) -> RBXScriptConnection)?,
	ChildAdded: ((self: Instance, handler: (child: Instance) -> ()) -> RBXScriptConnection)?,
	ChildRemoved: ((self: Instance, handler: (child: Instance) -> ()) -> RBXScriptConnection)?,
	DescendantAdded: ((self: Instance, handler: (descendant: Instance) -> ()) -> RBXScriptConnection)?,
	DescendantRemoving: ((self: Instance, handler: (descendant: Instance) -> ()) -> RBXScriptConnection)?,
	Destroying: ((self: Instance, handler: () -> ()) -> RBXScriptConnection)?,
	PropertyChanged: ((self: Instance, property: string) -> RBXScriptConnection)?,
}

export type GuiBase2d = Instance & {
	AutoLocalize: boolean?,
	RootLocalizationTable: LocalizationTable?,
	SelectionBehaviorDown: Enum.SelectionBehavior?,
	SelectionBehaviorLeft: Enum.SelectionBehavior?,
	SelectionBehaviorRight: Enum.SelectionBehavior?,
	SelectionBehaviorUp: Enum.SelectionBehavior?,
	SelectionGroup: boolean?,
}

export type LayerCollector = GuiBase2d & {
	Enabled: boolean?,
	ResetOnSpawn: boolean?,
	ZIndexBehavior: Enum.ZIndexBehavior?,
}

export type GuiObject = GuiBase2d & {
	AnchorPoint: Vector2?,
	BackgroundColor3: Color3?,
	BackgroundTransparency: number?,
	BorderColor3: Color3?,
	BorderMode: Enum.BorderMode?,
	BorderSizePixel: number?,
	ClipsDescendants: boolean?,
	LayoutOrder: number?,
	Position: UDim2?,
	Rotation: number?,
	Selectable: boolean?,
	SelectionImageObject: GuiObject?,
	Size: UDim2?,
	SizeConstraint: Enum.SizeConstraint?,
	Visible: boolean?,
	ZIndex: number?,
	AutomaticSize: Enum.AutomaticSize?,
}

export type ScreenGui = LayerCollector & {
	DisplayOrder: number?,
	IgnoreGuiInset: boolean?,
	ScreenInsets: Enum.ScreenInsets?,
	ClipToDeviceSafeArea: boolean?,
	SafeAreaCompatibility: Enum.SafeAreaCompatibility?,
}

export type Frame = GuiObject & {
	Style: Enum.FrameStyle?,
}

export type TextLabel = GuiObject & {
	FontFace: Font?,
	LineHeight: number?,
	MaxVisibleGraphemes: number?,
	OpenTypeFeatures: string?,
	RichText: boolean?,
	Text: string?,
	TextColor3: Color3?,
	TextDirection: Enum.TextDirection?,
	TextScaled: boolean?,
	TextSize: number?,
	TextStrokeColor3: Color3?,
	TextStrokeTransparency: number?,
	TextTransparency: number?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
}

export type TextBox = GuiObject & {
	ClearTextOnFocus: boolean?,
	CursorPosition: number?,
	MultiLine: boolean?,
	ShowNativeInput: boolean?,
	TextEditable: boolean?,
	ContentText: string?,
	FontFace: Font?,
	LineHeight: number?,
	MaxVisibleGraphemes: number?,
	OpenTypeFeatures: string?,
	OpenTypeFeaturesError: string?,
	PlaceholderColor3: Color3?,
	PlaceholderText: string?,
	RichText: boolean?,
	Text: string?,
	TextBounds: Vector2?,
	TextColor3: Color3?,
	TextDirection: Enum.TextDirection?,
	TextFits: boolean?,
	TextScaled: boolean?,
	TextSize: number?,
	TextStrokeColor3: Color3?,
	TextStrokeTransparency: number?,
	TextTransparency: number?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,
	SelectionStart: number?,

	CaptureFocus: ((self: TextBox) -> ())?,
	IsFocused: ((self: TextBox) -> boolean)?,
	ReleaseFocus: ((self: TextBox, submitted: boolean?) -> ())?,

	Focused: ((self: TextBox, handler: () -> ()) -> RBXScriptConnection)?,
	FocusLost: ((
		self: TextBox,
		handler: (enterPressed: boolean, inputThatCausedFocusLoss: InputObject) -> ()
	) -> RBXScriptConnection)?,
	ReturnPressedFromOnScreenKeyboard: ((self: TextBox, handler: () -> ()) -> RBXScriptConnection)?,
}

export type ImageLabel = GuiObject & {
	Image: string?,
	ImageColor3: Color3?,
	ImageContent: string?,
	ImageRectOffset: Vector2?,
	ImageRectSize: Vector2?,
	ImageTransparency: number?,
	IsLoaded: boolean?,
	ResampleMode: Enum.ResamplerMode?,
	ScaleType: Enum.ScaleType?,
	SliceCenter: Rect?,
	SliceScale: number?,
	TileSize: UDim2?,
}

export type GuiButton = GuiObject & {
	AutoButtonColor: boolean?,
	Modal: boolean?,
	Style: Enum.ButtonStyle?,
	HoverHapticEffect: HapticEffect?,
	PressHapticEffect: HapticEffect?,
	Selected: boolean?,

	Activated: (
		(self: GuiButton, handler: (inputObject: InputObject, clickCount: number) -> ()) -> RBXScriptConnection
	)?,
	MouseButton1Click: ((self: GuiButton, handler: () -> ()) -> RBXScriptConnection)?,
	MouseButton1Down: ((self: GuiButton, handler: (x: number, y: number) -> ()) -> RBXScriptConnection)?,
	MouseButton1Up: ((self: GuiButton, handler: (x: number, y: number) -> ()) -> RBXScriptConnection)?,
	MouseButton2Click: ((self: GuiButton, handler: () -> ()) -> RBXScriptConnection)?,
	MouseButton2Down: ((self: GuiButton, handler: (x: number, y: number) -> ()) -> RBXScriptConnection)?,
	MouseButton2Up: ((self: GuiButton, handler: (x: number, y: number) -> ()) -> RBXScriptConnection)?,
}

export type TextButton = GuiButton & {
	FontFace: Font?,
	LineHeight: number?,
	MaxVisibleGraphemes: number?,
	OpenTypeFeatures: string?,
	RichText: boolean?,
	Text: string?,
	TextColor3: Color3?,
	TextDirection: Enum.TextDirection?,
	TextScaled: boolean?,
	TextSize: number?,
	TextStrokeColor3: Color3?,
	TextStrokeTransparency: number?,
	TextTransparency: number?,
	TextTruncate: Enum.TextTruncate?,
	TextWrapped: boolean?,
	TextXAlignment: Enum.TextXAlignment?,
	TextYAlignment: Enum.TextYAlignment?,

	SetTextFromInput: ((self: TextButton, text: string) -> ())?,
}

export type ValueState = {
	Value: any,
	Connect: (...any) -> any,
}

export type Theme = { [any]: any }

export type Accent = {
	Light: { [any]: any },
	Dark: { [any]: any },
}

--// Components
export type BaseComponent = {
	Type: string,
	Theme: Theme,
	Structures: { [string]: Instance | { any } },
}

-- App
export type AppProperties = ScreenGui & {
	WindowPill: boolean?,
	Theme: Theme?,
	Accent: Accent?,
}

export type App = AppProperties & Components

-- Standalone Component
export type ComponentProperties = {
	Theme: Theme?,
	Accent: Accent?,
	Parent: Instance?,
}

export type ComponentContext = ComponentProperties & Components

-- App dumps
export type AppDumpOptions = {
	IncludeInstanceProperties: boolean?,
	IncludeInstanceTree: boolean?,
	Reset: boolean?,
}

export type AppRecorder = {
	Active: boolean,
	App: App,

	Start: (self: AppRecorder, options: AppDumpOptions?) -> AppRecorder,
	Stop: (self: AppRecorder) -> AppRecorder,
	Clear: (self: AppRecorder) -> AppRecorder,
	Dump: (self: AppRecorder, options: AppDumpOptions?) -> string,
}

-- Config
export type ConfigOptions = {
	Folder: string?,
	SubFolder: string?,
	AutoLoad: boolean?,
	Ignore: { string }?,

	Saved: ((name: string) -> ())?,
	Loaded: ((name: string) -> ())?,
	Deleted: ((name: string) -> ())?,
	Changed: (() -> ())?,
}

export type ConfigManager = {
	Current: string?,

	List: (self: ConfigManager) -> { string },
	Save: (self: ConfigManager, name: string?) -> (boolean, string?),
	Load: (self: ConfigManager, name: string?) -> (boolean, string?),
	Delete: (self: ConfigManager, name: string?) -> boolean,
	Rename: (self: ConfigManager, from: string, to: string) -> (boolean, string?),
	Exists: (self: ConfigManager, name: string) -> boolean,
	SetDefault: (self: ConfigManager, name: string?, scope: ("Account" | "All")?) -> (),
	ClearDefault: (self: ConfigManager, scope: ("Account" | "All")?) -> (),
	GetDefault: (self: ConfigManager) -> (string?, ("Account" | "All")?),
	LoadDefault: (self: ConfigManager) -> (boolean, string?),
}

export type ProfileOption = {
	Title: string,
	Icon: string?,
	Checked: boolean?,
	Changed: ((value: boolean) -> ())?,
	Pushed: (() -> ())?,
}

-- Window
export type WindowProperties = Frame & {
	-- Sidebar
	WindowControls: boolean?,
	CanUnload: boolean?,
	Unloaded: ((self: Window) -> ())?,

	-- Profile
	UserProfile: boolean?,
	ProfileName: string?,
	ProfileSubtitle: string?,
	ProfileImage: string?,
	CensorName: boolean?,
	HideAvatar: boolean?,
	ProfileOptions: { ProfileOption }?,
	ProfileSettingChanged: ((self: Window, setting: string, value: boolean) -> ())?,

	-- Key duration (paid scripts): unix timestamp, "Lifetime", or a custom string
	KeyExpires: (number | string | boolean)?,
	KeyDuration: number?,
	KeyExpired: ((self: Window) -> ())?,

	-- Mobile: auto-detected (phones / tablets); true / false forces it
	Mobile: boolean?,
	MobileScale: number?, -- default 0.8 on mobile
	MobileToggle: boolean?, -- round logo button that shows / hides the window (default: on for mobile)
	MobileToggleSide: ("Left" | "Right")?,

	-- Branding (logo header at the top of the sidebar)
	Logo: (string | number)?,
	Brand: string?,
	BrandSubtitle: string?,
	TabTitles: boolean?, -- titlebar shows the selected tab (default: on when a brand is set)

	-- Language picker
	Languages: { string }?,
	Language: string?,
	LanguageChanged: ((self: Window, language: string) -> ())?,

	-- Config manager (false turns it off). UI: window:Settings() or tab:ConfigManager()
	Config: (ConfigOptions | boolean)?,

	Searching: boolean?,
	Draggable: boolean?,
	Resizable: boolean?,
	Title: string?,
	Subtitle: string?,
	CanExit: boolean?,
    CanMinimize: boolean?,
    CanZoom: boolean?,
	Maximized: boolean?,
	Minimized: boolean?,

	Dropshadow: boolean?,
	UIBlur: boolean?,
}

export type Window = BaseComponent & Components & WindowProperties & {
	Configs: ConfigManager?,
	Unload: (self: Window) -> (),
	KeyStatus: (self: Window) -> (string, any),
	DisplayName: (self: Window) -> string,
}

-- Section
export type SectionProperties = Frame & {
	Title: string?,
	Disclosure: boolean?,
	Expanded: boolean?,
}

export type Section = BaseComponent & Components & SectionProperties

-- Tab
export type TabProperties = Frame & {
	Title: string?,
	Icon: string?,
	Indentation: number?,
	Selected: boolean?,
	Page: Page?,
}

export type Tab = BaseComponent & Components & TabProperties & {
	Navigate: (self: Tab, page: Page) -> nil,
	Structures: { [string]: Instance | { any }, Page: Page},
}

-- Form
export type FormProperties = Frame
export type Form = BaseComponent & Components & FormProperties

-- Row
export type RowProperties = Frame & {
	SearchIndex: string?,
	Title: string?,
	Subtitle: string?,
}

export type Row = BaseComponent & Components & RowProperties & {
	Left: (self: Row) -> Row,
	Right: (self: Row) -> Row,
}

-- Stack
export type StackProperties = Frame & {
	Padding: UDim?,
	HorizontalAlignment: Enum.HorizontalAlignment?,
	VerticalAlignment: Enum.VerticalAlignment?,
}

export type Stack = BaseComponent & Components & StackProperties

-- TitleStack
export type TitleStackProperties = Frame & {
	Title: string?,
	Subtitle: string?,
}

export type TitleStack = BaseComponent & Components & TitleStackProperties

-- PageSection
export type PageSectionProperties = Frame & {
	Title: string?,
	Subtitle: string?,
}

export type PageSection = BaseComponent & Components & PageSectionProperties

-- Page
export type PageProperties = ScrollingFrame
export type Page = BaseComponent & Components & PageProperties

-- Label
export type LabelProperties = TextLabel
export type Label = BaseComponent & Components & LabelProperties

-- Symbol
export type SymbolProperties = ImageLabel & {
	Style: ("Primary" | "Secondary")?,
}

export type Symbol = BaseComponent & Components & SymbolProperties

-- Toggle
export type ToggleProperties = Frame & {
	Flag: string?, -- saved by configs
	Value: boolean?,
	ValueChanged: ((self: Toggle, value: boolean) -> unknown)?,
}

export type Toggle = BaseComponent & Components & ToggleProperties

-- TextField
export type TextFieldProperties = Frame & {
	Flag: string?, -- saved by configs
	Placeholder: string?,
	Value: string?,
	TextChanged: ((self: TextField, text: string) -> unknown)?,
	ValueChanged: ((self: TextField, value: string) -> unknown)?,
}

export type TextField = BaseComponent & Components & TextFieldProperties

-- KeybindField
export type KeybindFieldProperties = Frame & {
	Placeholder: string?,
	Flag: string?,
	KeybindList: KeybindList?,
	KeybindName: string?,
	KeybindMode: ("Toggle" | "Hold" | "Always")?,
	Value: Enum.KeyCode?,
	BindPressed: ((
		self: KeybindField,
		value: Enum.KeyCode,
		inputComplete: boolean,
		gameProcessedEvent: boolean
	) -> unknown)?,
	ValueChanged: ((self: KeybindField, value: Enum.KeyCode) -> unknown)?,
}

export type KeybindField = BaseComponent & Components & KeybindFieldProperties

-- Slider
export type SliderProperties = ImageLabel & {
	Flag: string?, -- saved by configs
	Minimum: number?,
	Maximum: number?,
	Value: number?,
	ValueChanged: ((self: Slider, value: number) -> unknown)?,
}

export type Slider = BaseComponent & Components & SliderProperties

-- Button
export type ButtonProperties = TextButton & {
	State: ("Primary" | "Secondary" | "Destructive")?,
	Label: string?,
	Pushed: ((self: Button) -> unknown)?,
}

export type Button = BaseComponent & Components & ButtonProperties

-- Stepper
export type StepperProperties = ImageLabel & {
	Flag: string?, -- saved by configs
	Minimum: number?,
	Maximum: number?,
	Step: number?,
	Fielded: boolean?,
	Value: number?,
	ValueChanged: ((self: Stepper, value: number) -> unknown)?,
}

export type Stepper = BaseComponent & Components & StepperProperties & {
	Increment: () -> nil,
	Decrement: () -> nil,
}

-- RadioButtonGroup
export type RadioButtonGroupProperties = Frame & {
	Flag: string?, -- saved by configs
	Options: { [number]: string }?,
	Value: number?,
	ValueChanged: ((self: RadioButtonGroup, value: number) -> unknown)?,
}

export type RadioButtonGroup = BaseComponent & Components & RadioButtonGroupProperties & {
	Option: (Name: string?) -> Frame,
}

-- DropdownMenu
export type DropdownMenuAnchorConfig = {
	Object: GuiObject?,
	Element: GuiObject?,
	Label: GuiObject?,
	Option: number?,
	Offset: Vector2?,
	XOffset: number?,
	YOffset: number?,
}
export type DropdownMenuAnchor = GuiObject | DropdownMenuAnchorConfig

-- PopUpButton
export type PopUpButtonProperties = Frame & {
	Flag: string?, -- saved by configs
	Options: { [number]: string }?,
	Expanded: boolean?,
	Anchor: DropdownMenuAnchor?,
	Maximum: number?,
	Value: (number | { number })?,
	ValueChanged: ((self: PopUpButton, value: number | { number }) -> unknown)?,
}

export type PopUpButton = BaseComponent & Components & PopUpButtonProperties & {
	Option: (Name: string?) -> Frame,
	Remove: (Index: number?) -> nil,
}

-- PullDownButton
export type PullDownButtonProperties = Frame & {
	Options: { [number]: string }?,
	Expanded: boolean?,
	Anchor: DropdownMenuAnchor?,
	Label: string?,
	Value: number?,
	ValueChanged: ((self: PullDownButton, value: number) -> unknown)?,
}

export type PullDownButton = BaseComponent & Components & PullDownButtonProperties & {
	Option: (Name: string?) -> Frame,
	Remove: (Index: number?) -> nil,
}

-- Notification
export type NotificationProperties = Frame & {
	Title: string,
	Subtitle: string,
	App: string?,
	AppIcon: string?,
	Icon: string?,
	Duration: number?,
	Closed: ((self: Notification, fromUserInput: boolean?) -> unknown)?,
}

export type Notification = BaseComponent & Components & NotificationProperties & {
	Close: (self: Notification) -> nil,
}

-- ImageSurface
export type ImageSurfaceProperties = Frame & {
	Image: string?,
	ImageColor: Color3?,
	SurfaceColor: Color3?,
	Gradient: boolean?,
}

export type ImageSurface = BaseComponent & Components & ImageSurfaceProperties

-- Groupbox
export type GroupboxProperties = Frame & {
	Title: string?,
	Subtitle: string?,
	Description: string?,
	Icon: (string | number)?,
	Side: (string | number)?,
	Expanded: boolean?,
	Collapsed: boolean?,
	Collapsible: boolean?,
	SearchIndex: string?,
	ExpandedChanged: ((self: Groupbox, expanded: boolean) -> ())?,
}

export type Groupbox = BaseComponent & Components & GroupboxProperties

-- Columns
export type ColumnsProperties = {
	Count: number?,
	Spacing: number?,
}

export type Columns = BaseComponent & ColumnsProperties & {
	Column: (self: Columns, index: number) -> Components,
	Left: (self: Columns) -> Components,
	Right: (self: Columns) -> Components,
}

-- UpdateLog
export type UpdateLogEntry = string | { Type: string?, Text: string }

export type UpdateLogProperties = Frame & {
	Title: string?,
	Preview: number?,
	Expanded: boolean?,
	Entries: { UpdateLogEntry }?,
}

export type UpdateLog = BaseComponent & UpdateLogProperties & {
	Add: (self: UpdateLog, entry: UpdateLogEntry) -> any,
	Clear: (self: UpdateLog) -> (),
}

-- InviteCard
export type InviteCardProperties = Frame & {
	Title: string?,
	Subtitle: string?,
	Invite: string?,
	Icon: string?,
	Copied: ((self: InviteCard, invite: string, copied: boolean) -> ())?,
}

export type InviteCard = BaseComponent & InviteCardProperties

-- Dashboard
export type DashboardProperties = {
	Title: string?,
	Icon: string?,
	Selected: boolean?,
	Version: string?,
	UpdatesTitle: string?,
	LogsTitle: string?,
	Preview: number?,
	Logs: { UpdateLogEntry }?,
	LinksTitle: string?,
	Discord: string?,
	Links: { InviteCardProperties }?,
	Info: (boolean | { InfoItem })?,
	InfoTitle: string?,
}

export type Dashboard = BaseComponent & Components & {
	HomeTab: Tab,
	Info: InfoCard?,
	Updates: UpdateLog,
	Links: { InviteCard },
	Log: (self: Dashboard, entry: UpdateLogEntry) -> any,
}

-- InfoCard
export type InfoItem = {
	Label: string,
	Value: any, -- text, or a function returning (text, colorPair?) refreshed every second
}

export type InfoCardProperties = Frame & {
	Title: string?,
	Icon: (string | number)?,
	Items: { InfoItem }?,
}

export type InfoCard = BaseComponent & InfoCardProperties & {
	Add: (self: InfoCard, item: InfoItem) -> (),
	Refresh: (self: InfoCard) -> (),
}

-- ConfigManager
export type ConfigManagerProperties = {
	Title: string?,
	Subtitle: string?,
	Icon: (string | number)?,
	Side: (string | number)?,
	Manager: ConfigManager?,
	Config: ConfigOptions?,
}

export type ConfigManagerComponent = Groupbox & {
	Manager: ConfigManager,
	Refresh: (self: ConfigManagerComponent) -> (),
}

-- Settings
export type SettingsProperties = {
	Section: (string | boolean)?,
	Title: string?,
	Icon: (string | number)?,
	Selected: boolean?,
	MenuKey: Enum.KeyCode?,
	Watermark: Watermark?,
	KeybindList: KeybindList?,
	ThemeFlag: string?,
	AccentFlag: string?,
	MenuKeyFlag: string?,
}

-- ColorPicker
export type ColorPickerProperties = {
	Flag: string?, -- saved by configs (the Color3)
	Value: Color3?,
	Transparency: number?, -- give a number (0 = solid) to show the transparency bar
	Title: string?,
	ValueChanged: ((self: ColorPicker, color: Color3, transparency: number?) -> ())?,
}

export type ColorPicker = BaseComponent & ColorPickerProperties & {
	Open: (self: ColorPicker) -> (),
	Close: (self: ColorPicker) -> (),
}

-- ButtonRow
export type ButtonRowProperties = {
	Buttons: { ButtonProperties }?,
	Spacing: number?,
	Height: number?,
}

export type ButtonRow = BaseComponent & {
	Buttons: { Button },
	Add: (self: ButtonRow, properties: ButtonProperties) -> Button,
}

-- Watermark
export type WatermarkProperties = Frame & {
	Title: string?,
	Text: string?,
	Icon: string?,
	ShowFPS: boolean?,
	ShowPing: boolean?,
	ShowTime: boolean?,
	Draggable: boolean?,
}

export type Watermark = BaseComponent & WatermarkProperties

-- KeybindList
export type KeybindListEntryProperties = {
	Name: string?,
	Key: (Enum.KeyCode | Enum.UserInputType | string)?,
	Mode: ("Toggle" | "Hold" | "Always")?,
	Active: boolean?,
}

export type KeybindListEntry = KeybindListEntryProperties & {
	Remove: (self: KeybindListEntry) -> (),
	Toggle: (self: KeybindListEntry) -> (),
}

export type KeybindListProperties = Frame & {
	Title: string?,
	HideInactive: boolean?,
	Draggable: boolean?,
}

export type KeybindList = BaseComponent & KeybindListProperties & {
	Add: (self: KeybindList, properties: KeybindListEntryProperties) -> KeybindListEntry,
	Clear: (self: KeybindList) -> (),
}

-- Export
export type Components = {
	Window: (self: any, properties: WindowProperties?) -> Window,
	Section: (self: any, properties: SectionProperties?) -> Section,
	Tab: (self: any, properties: TabProperties?) -> Tab,
	Page: (self: any, properties: PageProperties?) -> Page,
	Form: (self: any, properties: FormProperties?) -> Form,
	Row: (self: any, properties: RowProperties?) -> Row,
	VStack: (self: any, properties: StackProperties?) -> Stack,
	HStack: (self: any, properties: StackProperties?) -> Stack,
	TitleStack: (self: any, properties: TitleStackProperties?) -> TitleStack,
	PageSection: (self: any, properties: PageSectionProperties?) -> PageSection,
	Label: (self: any, properties: LabelProperties) -> Label,
	Symbol: (self: any, properties: SymbolProperties) -> Symbol,
	Toggle: (self: any, properties: ToggleProperties) -> Toggle,
	TextField: (self: any, properties: TextFieldProperties) -> TextField,
	KeybindField: (self: any, properties: KeybindFieldProperties) -> KeybindField,
	Slider: (self: any, properties: SliderProperties) -> Slider,
	Button: (self: any, properties: ButtonProperties) -> Button,
	Stepper: (self: any, properties: StepperProperties) -> Stepper,
	RadioButtonGroup: (self: any, properties: RadioButtonGroupProperties) -> RadioButtonGroup,
	PopUpButton: (self: any, properties: PopUpButtonProperties) -> PopUpButton,
	PullDownButton: (self: any, properties: PullDownButtonProperties) -> PullDownButton,
	Notification: (self: any, properties: NotificationProperties) -> Notification,
	ImageSurface: (self: any, properties: ImageSurfaceProperties) -> ImageSurface,
	Groupbox: (self: any, properties: GroupboxProperties?) -> Groupbox,
	Columns: (self: any, properties: ColumnsProperties?) -> Columns,
	UpdateLog: (self: any, properties: UpdateLogProperties?) -> UpdateLog,
	InviteCard: (self: any, properties: InviteCardProperties?) -> InviteCard,
	Dashboard: (self: any, properties: DashboardProperties?) -> Dashboard,
	Watermark: (self: any, properties: WatermarkProperties?) -> Watermark,
	KeybindList: (self: any, properties: KeybindListProperties?) -> KeybindList,
	InfoCard: (self: any, properties: InfoCardProperties?) -> InfoCard,
	ConfigManager: (self: any, properties: ConfigManagerProperties?) -> ConfigManagerComponent,
	Settings: (self: any, properties: SettingsProperties?) -> Tab,
	ButtonRow: (self: any, properties: ButtonRowProperties?) -> ButtonRow,
	ColorPicker: (self: any, properties: ColorPickerProperties?) -> ColorPicker,
}

return 1
