# =================================================================================================
# GUI constants
# =================================================================================================
# Font sizes
const SECTION_FONTSIZE = 30
const CONTENT_FONTSIZE = 20

# Dimensions
const SLIDER_LINE_WIDTH = 20
const SCENE_CORNER_RADIUS = 20
const MENU_WIDTH = 400
const BORDER_WIDTH = 20
const SETTINGS_BORDER_WIDTH=10

# Inflow / Wall parameters
const MIN_ALTITUDE = 90
const MAX_ALTITUDE = 120
const DEFAULT_ALTITUDE = 105

const MIN_VELOCITY = 5000
const MAX_VELOCITY = 10000
const DEFAULT_VELOCITY = 7500
const INFLOW_TEMPERATURE = 200

const DEFAULT_ACCOMODATION_COEFFICIENT = 0.0
const MIN_WALL_LENGTH = 5

# visualization
const NUM_PARTICLES_VISU = 1*10^5

# Colors
const BLUE_VERY_LIGHT = RGBf(0.8, 0.9, 1)
const BLUE_LIGHT = RGBf(100/255, 150/255, 200/255)
const BLUE = RGBf(67/255, 100/255, 140/255)
const BLUE_DARK = RGBf(19/255, 51/255, 94/255)
const BACKGROUND_COLOR = RGBf(0,0,0)
const DISPLAY_BACKGROUND_COLOR = RGBf(1, 1, 1)

# Shape files
const SHAPE_FILES = ["triangle.jl" "circle.jl"; "random.jl" "capsule.jl"]

# =================================================================================================
# Simulation constants
# =================================================================================================
const MAX_NUM_PARTICLES = 6*10^5
const NUM_CELLS = (120, 80)
const MAX_NUM_WALLS_PER_CELL = 1000
const WALL_TEMPERATURE = 1000

# Species parameters
const WEIGHTING = 5E15
const MASS = 6.63E-26
const REF_TEMP = 273
const REF_EXP = 0.77
const REF_DIA = 4.05E-10

const BOLTZMANN_CONST = 1.380649E-23

const MESH_LENGTH = ((1920-MENU_WIDTH-2*BORDER_WIDTH)/(1080-2*BORDER_WIDTH), 1)