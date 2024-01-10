# Mounain sprite: https://pixelartmaker-data-78746291193.nyc3.digitaloceanspaces.com/image/8b6adcaddffab6b.png
# Jungle tree sprite: https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/693c2b0f-957e-4b54-9677-2a06fc5ac5b5/d6bhqqv-51bdf853-d469-4260-9126-37eff0cb6431.png?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwic3ViIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsImF1ZCI6WyJ1cm46c2VydmljZTpmaWxlLmRvd25sb2FkIl0sIm9iaiI6W1t7InBhdGgiOiIvZi82OTNjMmIwZi05NTdlLTRiNTQtOTY3Ny0yYTA2ZmM1YWM1YjUvZDZiaHFxdi01MWJkZjg1My1kNDY5LTQyNjAtOTEyNi0zN2VmZjBjYjY0MzEucG5nIn1dXX0.oxzSG-F0P2ytIpjDWpSK-syBW3dx2jhidj3fyG4quXM
# Fir tree sprite: https://opengameart.org/sites/default/files/pine-tree-isaiah658-bigger-preview.png
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

const BIOME_ID = 0
const BIOME_NAME = 1
const BIOME_COLOR = 2
const BIOME_BASE_FOOD = 3
const BIOME_RAINFALL = 4


var id:Vector2i
var biome_hash:int = 0
var temp:float
var biome:Array


var food:float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	biome = Globals.Biomes["default"]
	#random_biome()
	update_color()
	update_food(biome[BIOME_BASE_FOOD])


func random_biome():
	var keys = Globals.Biomes.keys() as Array
	var key = keys.pick_random()
	while key == "default":
		key = keys.pick_random()
	biome = Globals.Biomes[key]
	update_color()
	update_food(biome[BIOME_BASE_FOOD])
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

func update_food(food_amount:float):
	food = food_amount

func update_color():
	$Sprite2D.modulate = biome[BIOME_COLOR]


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
