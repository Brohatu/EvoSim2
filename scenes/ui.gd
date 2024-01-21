extends CanvasLayer


signal generate
signal start()
signal pause(paused)

const AGE = 0
const DIET = 1
const SIZE = 2
const HUNGER = 3

const BIOME = 0
const VEGE = 1
const MEAT = 2
const RIVER = 3

const LABEL = 0
const VALUE = 1


var paused:bool = false
var c:Creature
var t:Tile

func reset():
	$Header/TurnCounter.text = "Turn: 0"

func update():
	if c:
		$Data/CreatureDataContainer/CreatureData/Age/Val.text = str(c.age)
		$Data/CreatureDataContainer/CreatureData/Diet/Val.text = str(c.genes.diet)
		$Data/CreatureDataContainer/CreatureData/Size/Val.text = str(c.genes.size)
		$Data/CreatureDataContainer/CreatureData/Hunger/Val.text = str(c.hunger)
		#location
		if c.hunger > 100.0 or c.age > c.genes.lifespan:
			c = null
	
	if t:
		$Data/TileDataContainer/VBoxContainer/Biome/Val.text = t.biome_name
		$Data/TileDataContainer/VBoxContainer/Vegetation/Val.text = str(t.vegetation)
		$Data/TileDataContainer/VBoxContainer/Meat/Val.text = str(t.carrion)
		$Data/TileDataContainer/VBoxContainer/River/Val.text = str(t.river_volume)
		#precip
		#water_volume
	

func display_creature(creature:Creature):
	c = creature
	$Data/CreatureDataContainer/CreatureData/Age/Val.text = str(c.age)
	$Data/CreatureDataContainer/CreatureData/Diet/Val.text = str(c.genes.diet)
	$Data/CreatureDataContainer/CreatureData/Size/Val.text = str(c.genes.size)
	$Data/CreatureDataContainer/CreatureData/Hunger/Val.text = str(c.hunger)

	
func display_tile(tile:Tile):
	t = tile
	$Data/TileDataContainer/VBoxContainer/Biome/Val.text = t.biome_name
	$Data/TileDataContainer/VBoxContainer/Vegetation/Val.text = str(t.vegetation)
	$Data/TileDataContainer/VBoxContainer/Meat/Val.text = str(t.carrion)
	$Data/TileDataContainer/VBoxContainer/River/Val.text = str(t.river_volume)
		

func _on_button_pressed():
	pass


func _on_generate_pressed():
	generate.emit()


func _on_start_pressed():
	start.emit()


func _on_pause_pressed():
	paused = !paused
	pause.emit(paused)
