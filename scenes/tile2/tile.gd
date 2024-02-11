extends Area2D

class_name Tile

### Signals
signal placed_creature(tile)
signal tile_data_sent(tile)

### Enums
enum Region {
	Polar,
	Dry,
	Temperate,
	Tropic
}

### Constants
const mountain_min_height = 400

### Export variables
#region
## Factors
@export_range(30,150) var altitude_scale = 80.0:
	set(val):
		altitude_scale = val
@export var heightmap = false
@export var rivermap = false 
@export var biomemap = true
#endregion
### Variables
#region
## UI
var id:Vector2i
var col:Color
var highlighted:bool = false

## Position
var w_dimensions:Vector2
var temp_region
var latitude:float
var pole_to_equator
var downhill:Tile
var ray:RayCast2D

## Biome
var region:Region
var altitude:float:
	set(val):
		#altitude = pow(2,val/altitude_scale)
		altitude = val
var temperature:int = 25
var precipitation:int
var river_volume:int = 0
var water_access
var biome:Array

##Tile contents
#region 
# Vegetation
var vegetation_max:int
var vegetation:int
var growth_rate
# Meat
var meat
# Waste (material available for decomposers)
var plant_waste
var animal_waste
# Decomposers (control rate of decay -> plant regrowth)
var plant_decomposers = 0
var animal_decomposers = 0
# Scent (list of creatures that have passed through)
# the freshest scents will always be at the end of the array
var scent_list:Array = []

#endregion

#endregion
###############################################################################
### Built-in methods
#region
## Object creation methods ##
#region
func _init():
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	ray = $RayCast2D
	reset()
	_calc_latitude()
	_calc_region()
	_update_text()
	_update_color()


#endregion
## Object runtime methods ##
#region
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if highlighted:
		if Input.is_action_just_pressed("add_creature"):
			placed_creature.emit(self)
		if Input.is_action_just_pressed("select"):
			tile_data_sent.emit(self)

#endregion


#endregion
###############################################################################
### Public methods
#region
# Calculate vegetation growth and waste processing
func process_turn():
	
	
	for s in scent_list:
		s["Strength"] -= 1
	scent_list = scent_list.filter(func(s): return s["Strength"] > 0)
	#update_vegetation()
	update_veg_basic()
	_update_sprite()



func update():
	_update_color()
	_update_text()
	_update_sprite()



## Tile generation methods ##
#region
func generate():
	calc_temp()
	calc_precip()
	
	water_access = precipitation/10 + river_volume
	biome = calc_biome()
	
	# show elevation via mountain sprite once a sufficient altitude is reached
	if altitude > mountain_min_height:
		$Mountains.visible = true
		$Mountains.scale = Vector2.ONE * altitude/1000
	
	animal_waste = 0.0
	
	var deviation_from_ideal_temp = abs(25 - temperature)
	vegetation_max = precipitation * (25 - deviation_from_ideal_temp)
	vegetation = vegetation_max * 0.8
	#if vegetation:
		#update_decomposers()
		#update_plantwaste()
		#update_growthrate()
	
	#$"Tile Sensor".monitoring = false
	#$"Tile Sensor".monitorable = false
	ray.enabled = false





func reset():
	$"Tile Sensor".monitoring = true
	$"Tile Sensor".monitorable = true
	ray.enabled = true
	altitude = 0
	temperature = 0
	precipitation = 0
	river_volume = 0
	water_access = 0
	vegetation_max = 0
	vegetation = 0
	growth_rate = 0
	meat = 0
	plant_waste = 0
	animal_waste = 0
	scent_list.clear()
	
	plant_decomposers = 0
	animal_decomposers = 0
	biome = Globals.Biomes["Default"]
	for child in $Sprites.get_children():
		child.visible = false

#endregion




#endregion
###############################################################################
### Private methods
#region
func get_overlapping_tiles():
	var sensor = $"Tile Sensor" as Area2D
	return sensor.get_overlapping_areas()

func get_nearest_coast():
	var current:Tile
	#var saved:Tile
	var distance_new
	var distance_saved
	
	for i in range(60):
		ray.force_raycast_update()
		current = ray.get_collider() as Tile
		if current:
			#if current != saved:
			distance_new = global_position.distance_to(current.global_position)
			if !distance_saved or distance_new < distance_saved:
					distance_saved = distance_new
			
		ray.rotate(PI/30)
	if not distance_saved:
		return 100000
	return distance_saved


## Environment calculation methods ##
#region
func _calc_latitude():
	pole_to_equator = w_dimensions.y / 2.0 - 1
	if id.y > pole_to_equator:
		latitude = pole_to_equator - (id.y - pole_to_equator) + 1 
	else:
		latitude = id.y


func _calc_region():
	temp_region = latitude / w_dimensions.y
	if temp_region < Globals.POLAR_N or temp_region > Globals.POLAR_S:
		region = Region.Polar
	elif temp_region < Globals.TEMPERATE_N or temp_region > Globals.TEMPERATE_S:
		region = Region.Temperate
	elif temp_region < Globals.DRY_N or temp_region > Globals.DRY_S:
		region = Region.Dry
	else:
		region = Region.Tropic


func calc_downhill():
	var neighbours = get_overlapping_tiles()
	neighbours.sort_custom(func(a,b): return a.altitude < b.altitude)
	if neighbours[0].altitude < altitude:
		downhill = neighbours[0]
	else:
		downhill = self


func river_flow():
	river_volume += 1
	#if water_access > 10:
		#biome = Globals.Biomes["Ocean"]
	if downhill != self:
		downhill.river_flow()


func equalise_water_levels():
	var neighbours:Array = get_overlapping_tiles()
	neighbours = neighbours.filter(func(n): return n.altitude >= altitude)
	if neighbours:
		var total_water = water_access
		for n in neighbours:
			total_water += n.water_access
		var water_share = total_water / (neighbours.size()+1.0)
		water_access = water_share
		for n in neighbours:
			n.water_access = water_share


func calc_temp():
	# 9.8 °C/km in dry airww
	# 3.6 to 9.2 °C/km in saturated air
	# go with 5-6°C on average
	temperature = latitude / pole_to_equator * 35 - 10 + randi_range(-1,1)       # - (altitude/100) + randi_range(-2, 2) #Globals.Regions_base_temp[region]
	#temperature *= 1.1
	#temperature -= altitude * 5.0


func calc_precip():
	var rain_raw = 0.0
	if biome[Globals.BIOME_ID] != Globals.Biomes["Ocean"][Globals.BIOME_ID]:
		var distance = get_nearest_coast()
		var deviation_from_ideal_temp = abs(25 - temperature)
		rain_raw = max(0,25 - deviation_from_ideal_temp) * 500 / distance
	match region:
		Region.Tropic:
			precipitation = rain_raw * 10
		Region.Dry:
			precipitation = rain_raw
		Region.Temperate:
			precipitation = rain_raw * 15
		Region.Polar:
			precipitation = rain_raw * 2
	#water_access += precipitation


func calc_biome():
	#Biome:
		#[Temperature,
		#Precipitation]
	#Trop RForest	[>= 20,  >= 300]
	#Savannah		[>= 20,  >= 50]
	#Temp RForest	[>= 5, 	 >= 200]
	#Decid Forest	[>= 5, 	 >= 100]
	#Taiga			[>= -5,  >= 50]
	#Grassland		[>= 5, 	 >= 25]
	#Desert			[>= -5,  >= 0]
	#Tundra			[>= -30, >= 0]
	if altitude < 0:
		if temperature > 0:
			return Globals.Biomes["Ocean"]
		else:
			return Globals.Biomes["Sea Ice"]
	else:
		if temperature >= 20:
			if precipitation >= 300:
				if altitude < 50:
					$Sprites/Swamp.visible = true
					return Globals.Biomes["Swamp"]
				$Sprites/Rainforest.visible = true
				return Globals.Biomes["Rainforest"]
			elif precipitation >= 50:
				$Sprites/Acacia.visible = true
				return Globals.Biomes["Savannah"] # Savannah
		if temperature >= 5:
			if precipitation >= 200:
				$Sprites/Fern.visible = true
				return Globals.Biomes["TempRainforest"] # Temperate Rainforest, using Swamp for the moment
			elif precipitation >= 100:
				$Sprites/Deciduous.visible = true
				return Globals.Biomes["Woods"]
			elif precipitation >= 25:
				return Globals.Biomes["Grassland"]
		if temperature >= -5:
			if precipitation >= 50:
				$Sprites/Coniferous.visible = true
				return Globals.Biomes["Taiga"]
			elif precipitation >= 10:
				return Globals.Biomes["Steppe"]
			elif precipitation >= 0:
				return Globals.Biomes["Desert"]
		elif temperature >= -30:
			return Globals.Biomes["Polar"] # change name to tundra

#endregion


## Tile update methods ##
#region
func _update_color():
	if heightmap:
		$Sprite2D.modulate = Globals.Biomes["Default"][Globals.BIOME_COLOR]
		$Sprite2D.modulate *= (altitude/1000)
	if rivermap:
		$Sprite2D.modulate = Color.BLACK + Color(0,0,0.05) * river_volume
	if biomemap:
		$Sprite2D.modulate = biome[Globals.BIOME_COLOR]
		if temperature < 5:
			$Sprite2D.modulate += Color.SNOW / max(2,temperature*2)
	$Sprite2D.modulate.a = 1.0
	#$Sprite2D.modulate = (Color(0,0,1) * water_access / 40)


func _update_text():
	$Control/VBoxContainer/Label3.text = str(temp_region)
	$Control/VBoxContainer/Label.text = str(temperature)
	$Control/VBoxContainer/Label2.text = str(altitude)


func _update_sprite():
	for child in $Sprites.get_children():
		if child.visible:
			child.scale = Vector2.ONE * sqrt(float(vegetation))/100


func update_veg_basic():
	if vegetation < vegetation_max:
		vegetation += vegetation_max * 0.1
	elif vegetation > vegetation_max:
		vegetation -= (vegetation - vegetation_max)/10


func update_plantwaste():
	var overgrown = max(0,vegetation - vegetation_max)
	var dead_plants = vegetation / 10
	plant_waste += dead_plants + overgrown
	vegetation -= dead_plants + overgrown


func update_decomposers():
	if plant_decomposers < plant_waste:
		plant_decomposers += 1
	elif plant_decomposers > plant_waste:
		plant_decomposers = plant_waste
	
	if animal_decomposers < animal_waste:
		animal_decomposers += 1
	elif animal_decomposers > animal_waste:
		animal_decomposers = animal_waste
	
	



func update_growthrate():
	if vegetation > 0:
		growth_rate = ((plant_decomposers + animal_decomposers) / vegetation)
	


func update_vegetation():
	update_plantwaste()
	update_decomposers()
	update_growthrate()
	vegetation += growth_rate

#endregion

## Input methods ##
#region
func _on_mouse_entered():
	highlighted = true
	$Sprite2D.modulate += biome[Globals.BIOME_COLOR] * 0.2


func _on_mouse_exited():
	highlighted = false
	_update_color()

#endregion


#endregion
