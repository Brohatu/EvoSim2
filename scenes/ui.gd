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
var pop_count

func reset():
	$Header/TurnCounter.text = "Turn: 0"

func new_tile(tile):
	t = tile
	display_tile()

func new_creature(creature):
	c = creature
	display_creature()

func update():
	if c:
		display_creature()

		if (c.food_need > 100.0 
				or c.water_need > 100.0
				or c.age > c.genes["Lifespan"]
		):
			c = null
	
	if t:
		display_tile()
	
	

func display_creature():
	$Data/CreatureDataContainer/CreatureData/Location/Val.text = str(c.location.id.x, ", ", c.location.id.y)
	$Data/CreatureDataContainer/CreatureData/Age/Val.text = str(c.age)
	$Data/CreatureDataContainer/CreatureData/Sex/Val.text = "Female" if c.genes["Female"] else "Male"
	$Data/CreatureDataContainer/CreatureData/Diet/Val.text = str(c.genes["Diet"].plants) + ", " + str(c.genes["Diet"].meat)
	$Data/CreatureDataContainer/CreatureData/Size/Val.text = str(c.genes["Size"])
	$Data/CreatureDataContainer/CreatureData/Hunger/Val.text = str(int(c.food_need))
	$Data/CreatureDataContainer/CreatureData/Thirst/Val.text = str(int(c.water_need))
	$Data/CreatureDataContainer/CreatureData/Horny/Val.text = str(c.love_need)
	if c.genes["Female"]:
		$Data/CreatureDataContainer/CreatureData/Pregnant.visible = true
		$Data/CreatureDataContainer/CreatureData/Pregnant/Val.text = "Yes" if c.pregnant[0] else "No"
	else:
		$Data/CreatureDataContainer/CreatureData/Pregnant.visible = false
	$Data/CreatureDataContainer/CreatureData/Action/Val.text = c.Action.keys()[c._action]


func display_tile():
	$Data/TileDataContainer/TileData/Biome/Val.text = t.biome[Globals.BIOME_NAME]
	$Data/TileDataContainer/TileData/Region/Val.text = Tile.Region.keys()[t.region]
	$Data/TileDataContainer/TileData/Temperature/Val.text = str(t.temperature)
	$Data/TileDataContainer/TileData/Altitude/Val.text = str(int(t.altitude))
	$Data/TileDataContainer/TileData/Precipitation/Val.text = str(t.precipitation)
	$Data/TileDataContainer/TileData/Vegetation/Val.text = str(t.vegetation)
	$Data/TileDataContainer/TileData/PlantWaste/Val.text = str(t.plant_waste)
	$Data/TileDataContainer/TileData/Growth/Val.text = str(t.growth_rate)
	$Data/TileDataContainer/TileData/Decomposers/Val.text = str(t.plant_decomposers + t.animal_decomposers)
	$Data/TileDataContainer/TileData/VegMax/Val.text = str(t.vegetation_max)
	$Data/TileDataContainer/TileData/Meat/Val.text = str(t.meat)
	$Data/TileDataContainer/TileData/River/Val.text = str(t.river_volume)
	



func display_population(new_pop_count):
	if new_pop_count != pop_count:
		pop_count = new_pop_count
		$Data/PopulationDataContainer/PopulationData/Population/Val.text = str(pop_count)

func _on_button_pressed():
	pass


func _on_generate_pressed():
	generate.emit()


func _on_start_pressed():
	start.emit()


func _on_pause_pressed():
	paused = !paused
	pause.emit(paused)
