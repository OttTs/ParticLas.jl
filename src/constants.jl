const UNUSED_THREADS = 1 # I do not know what GLMakie/GLFW is doing...

const MAX_NUM_PARTICLES_PER_THREAD = 10^5
const NUM_CELLS = (120, 80)
const MESH_LENGTH = (1.2, 1)

const MIN_ALTITUDE = 90
const MAX_ALTITUDE = 120
const DEFAULT_ALTITUDE = 90

const MIN_VELOCITY = 5000
const MAX_VELOCITY = 10000
const DEFAULT_VELOCITY = 5000

const DEFAULT_ACCOMODATION_COEFFICIENT = 0.0

const SCENE_CORNER_RADIUS = 20
const MENU_WIDTH = 400
const BORDER_WIDTH = 20
const SETTINGS_BORDER_WIDTH=10

const SECTION_FONTSIZE = 30
const CONTENT_FONTSIZE = 20

const BACKGROUND_COLOR = RGBf(19/255, 51/255, 94/255)
const MENU_BACKGROUND_COLOR = RGBf(1, 1, 1)
const DISPLAY_BACKGROUND_COLOR = RGBf(1, 1, 1)

const SLIDER_LINE_WIDTH = 20
const SLIDER_COLOR_RIGHT = RGBf(88/255, 176/255, 181/255)
const SLIDER_COLOR_LEFT = RGBf(67/255, 120/255, 169/255)
const SLIDER_COLOR_CIRCLE = RGBf(19/255, 51/255, 94/255)

const MENU_COLOR_ACTIVE = RGBf(88/255, 176/255, 181/255)
const MENU_COLOR_HOVER = RGBf(88/255, 176/255, 181/255)
const MENU_COLOR_EVEN = RGBf(205/255, 229/255, 236/255)
const MENU_COLOR_ODD = RGBf(205/255, 229/255, 236/255)
const MENU_COLOR_INACTIVE = RGBf(205/255, 229/255, 236/255)

const BUTTON_WIDTH = 200
const BUTTON_COLOR_INACTIVE = RGBf(205/255, 229/255, 236/255)
const BUTTON_COLOR_ACTIVE = RGBf(19/255, 51/255, 94/255)
const BUTTON_COLOR_HOVER = RGBf(88/255, 176/255, 181/255)

const FPS = 60
const BOLTZMANN_CONST = 1.380649E-23