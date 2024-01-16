# Mountain sprite: https://pixelartmaker-data-78746291193.nyc3.digitaloceanspaces.com/image/8b6adcaddffab6b.png
# Jungle tree sprite: https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/693c2b0f-957e-4b54-9677-2a06fc5ac5b5/d6bhqqv-51bdf853-d469-4260-9126-37eff0cb6431.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwic3ViIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImF1ZCI6WyJ1cm46c2VydmljZTpmaWxlLmRvd25sb2FkIl0sIm9iaiI6W1t7InBhdGgiOiIvZi82OTNjMmIwZi05NTdlLTRiNTQtOTY3Ny0yYTA2ZmM1YWM1YjUvZDZiaHFxdi01MWJkZjg1My1kNDY5LTQyNjAtOTEyNi0zN2VmZjBjYjY0MzEucG5nIn1dXX0.oxzSG-F0P2ytIpjDWpSK-syBW3dx2jhidj3fyG4quXM
# Fir tree sprite: https://opengameart.org/sites/default/files/pine-tree-isaiah658-bigger-preview.png
# river sprite:https://pixelartmaker-data-78746291193.nyc3.digitaloceanspaces.com/image/34d15e33bfd5c4c.png
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
signal move_camera(pos:Vector2)

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

var id:Vector2i
var region:Region
var biome_hash:int = 0
var temp:float
var biome:Array
var hight:float = 0.0
var food:float = 1.0
var precip:float = 0.0
# used to hold the new precip value while the remaining tiles on the map have
# their precip calculated
var precip_temp:float
var has_river:bool = false
var river_size:int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	biome = Globals.Biomes["Ocean"]
	#random_biome()
	update()


func reset():
	biome_hash = 0
	temp = 0.0
	precip = 0.0
	biome = Globals.Biomes["Ocean"]
	has_river = false
	river_size = 0
	update()



func random_biome():
	var keys = Globals.Biomes.keys() as Array
	var key = keys.pick_random()
	while key == "default":
		key = keys.pick_random()
	biome = Globals.Biomes[key]
	update()
	biome_hash = biome.hash()


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
		"Woods":
			$Sprites/Forest.visible = true
		"Taiga":
			$Sprites/Forest.visible = true
		"Scrubland":
			$Sprites/Scrubland.visible = true
		"Polar":
			#for child in $Control.get_children():
				#child.theme_override_colors/font_shadow
			pass
	if has_river:
		precip += 5 * river_size
		$Control/River.text = "R: " + str(river_size)
		$Sprites/River.visible = true
	else:
		$Control/River.text = ""
	biome_hash = biome.hash()
	$Control/Precipitation.text = str(precip)

func update_food(food_amount:float):
	food = food_amount

func update_color():
	$Sprite2D.modulate = biome[BIOME_COLOR]


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
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			move_camera.emit(get_global_mouse_position())
