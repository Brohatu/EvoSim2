# Mountain sprite: https://pixelartmaker-data-78746291193.nyc3.digitaloceanspaces.com/image/8b6adcaddffab6b.png
# Jungle tree sprite: https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/693c2b0f-957e-4b54-9677-2a06fc5ac5b5/d6bhqqv-51bdf853-d469-4260-9126-37eff0cb6431.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwic3ViIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImF1ZCI6WyJ1cm46c2VydmljZTpmaWxlLmRvd25sb2FkIl0sIm9iaiI6W1t7InBhdGgiOiIvZi82OTNjMmIwZi05NTdlLTRiNTQtOTY3Ny0yYTA2ZmM1YWM1YjUvZDZiaHFxdi01MWJkZjg1My1kNDY5LTQyNjAtOTEyNi0zN2VmZjBjYjY0MzEucG5nIn1dXX0.oxzSG-F0P2ytIpjDWpSK-syBW3dx2jhidj3fyG4quXM
# Fir tree sprite: https://opengameart.org/sites/default/files/pine-tree-isaiah658-bigger-preview.png
# river sprite:https://pixelartmaker-data-78746291193.nyc3.digitaloceanspaces.com/image/34d15e33bfd5c4c.png
# https://static.vecteezy.com/system/resources/previews/016/006/221/original/beautiful-mangrove-tree-illustrations-vector.jpg
extends Area2D

class_name Tile



#enum Biome {
	#Grassland,
	#Desert,
	#Ocean,
	#Mountain,
	#Woods,
	#Rainforest
#}
signal place_creature(tile)
signal tile_data(tile)

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2
const BIOME_BASE_FOOD = 3
const BIOME_RAINFALL = 4

enum Region {
	Polar,
	Temperate,
	Dry,
	Tropic
}

##basic vars
var id:Vector2i
var region:Region
var biome_name:String
var temp:float
var biome:Array
var hight:float = 0.0
var highlighted:bool = false

## Food vars
# Plants
var vegetation_max:float
var vegetation:float = 0.0

# Meat
var carrion:float = 0.0


## Water vars
# precipitation vars
var precip:float = 0.0
# used to hold the new precip value while the remaining tiles on the map have
# their precip calculated
var precip_temp:float

# river vars
var has_river:bool = false
var river_size:int = 0
var river_volume:float = 0.0
var river_sources:Array[Tile]
var river_sink:Tile

# precipitation + river
var water_access:float

var requested_vegetation:float
var requested_meat:float


# Called when the node enters the scene tree for the first time.
func _ready():
	biome = Globals.Biomes["Ocean"]
	vegetation_max = biome[BIOME_BASE_FOOD]
	#random_biome()
	$Control/ID.text = str(id.x) + ", " + str(id.y)
	update()

func _process(_delta):
	if highlighted:
		if Input.is_action_just_pressed("change_biome"):
			var new_biome:Array
			var keys = Globals.Biomes.keys()
			var size = keys.size()
			var old_key = biome[BIOME_NAME]
			var old_key_i = keys.find(old_key)
			if old_key_i < size - 1:
				new_biome = Globals.Biomes[keys[old_key_i + 1]]
			else:
				new_biome = Globals.Biomes[keys[1]]
			biome = new_biome
			update()
		if Input.is_action_just_pressed("add_creature"):
			place_creature.emit(self)
		if Input.is_action_just_pressed("select") and highlighted:
			tile_data.emit(self)


func process_turn():
	if vegetation < vegetation_max:
		vegetation += min(vegetation_max/50.0, vegetation_max - vegetation)
	if carrion > 0.0:
		carrion -= min(1.0, carrion)



func food_request_basic():
	var _preferred_food = randf_range(0.0,10.0)
	

func food_request(_c:Creature):
	var preferred_food = randf_range(0.0,10.0)
	if preferred_food < _c.genes.diet:
		requested_vegetation += _c.genes.food_need
	else:
		requested_meat += _c.genes.food_need


func reset():
	biome_name = ""
	temp = 0.0
	precip = 0.0
	biome = Globals.Biomes["Ocean"]
	has_river = false
	river_size = 0
	carrion = 0.0
	update()


func random_biome():
	var keys = Globals.Biomes.keys() as Array
	var key = keys.pick_random()
	while key == "default":
		key = keys.pick_random()
	biome = Globals.Biomes[key]
	update()
	biome_name = biome[BIOME_NAME]


func update():
	
	update_food(biome[BIOME_BASE_FOOD])
	update_color()
	
	var sprites = $Sprites.get_children()
	for s in sprites:
		s.visible = false
	match biome[BIOME_NAME]:
		"Mountain":
			$Sprites/Mountains.visible = true
		"Rainforest":
			$Sprites/Jungle.visible = true
			for i in range(0, $Sprites/Jungle.get_child_count()/max(vegetation_max - vegetation,0.0001)):
				$Sprites/Jungle.get_child(i).visible = false
		"Woods":
			$Sprites/Forest.visible = true
		"Taiga":
			$Sprites/Forest.visible = true
		"Floodplain":
			$Sprites/Scrubland.visible = true
		"Scrubland":
			$Sprites/Scrubland.visible = true
		"Polar":
			#for child in $Control.get_children():
				#child.theme_override_colors/font_shadow
			pass
		"Swamp":
			$Sprites/Swamp.visible = true
	update_water_volume()
	biome_name = biome[BIOME_NAME]
	$Control/Precipitation.text = str(water_access)



func update_food(food_amount:float):
	vegetation_max = food_amount

func update_color():
	$Sprite2D.modulate = biome[BIOME_COLOR]


func update_water_volume():
	water_access = precip
	if has_river:
		water_access += river_volume
		$Control/River.text = "R: " + str(river_size)
		$Sprites/River.visible = true
	else:
		$Control/River.text = ""

func update_river():
	river_volume = 5.0
	for src in river_sources:
		river_volume += src.river_volume
	if river_sink:
		river_sink.update_river() if river_sink.biome[BIOME_NAME] != "Ocean" else print(river_sink.id, " Ocean reached")

func determine_biome(temp_region):
	if temp_region < Globals.POLAR_N or temp_region > Globals.POLAR_S:
		region = Region.Polar
	elif temp_region < Globals.TEMPERATE_N or temp_region > Globals.TEMPERATE_S:
		region = Region.Temperate
	elif temp_region < Globals.DRY_N or temp_region > Globals.DRY_S:
		region = Region.Dry
	else:
		temp_region = Region.Tropic
	match region:
		Region.Polar:
			biome = Globals.Biomes["Polar"]
		Region.Temperate:
			biome = Globals.Biomes["Woods"]
		Region.Dry:
			biome = Globals.Biomes["Grassland"]
		Region.Tropic:
			biome = Globals.Biomes["Rainforest"]
		_:
			biome = Globals.Biomes["Default"]



## get list of keys
## find current key
## find index of current key in keys
## use new key to get new biome
func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var new_biome:Array
			var keys = Globals.Biomes.keys()
			var size = keys.size()
			var old_key = biome[BIOME_NAME]
			var old_key_i = keys.find(old_key)
			if old_key_i < size - 1:
				new_biome = Globals.Biomes[keys[old_key_i + 1]]
			else:
				new_biome = Globals.Biomes[keys[1]]
			biome = new_biome
			update()
		#if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			#move_camera.emit(get_global_mouse_position())


func _on_mouse_entered():
	highlighted = true


func _on_mouse_exited():
	highlighted = false
