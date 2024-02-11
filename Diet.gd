class_name Diet
extends Resource

## Place description here

###############################################################################
### Signals
#region

#endregion

## Enums
#region

#endregion

## Constants
#region
const MEAT = 0
const PLANTS = 1
#endregion

## Exported variables
#region
# Diet values should sum to 10
@export var diet = {
	"Meat" = 5,
	"Plants" = 5
}

#endregion

## Public variables
#region

#endregion

## Private variables
#region

#endregion

## Onready variables
#region

#endregion

###############################################################################
## Built-in virtual methods
#region

#endregion

###############################################################################
## Public methods
#region
func mutate():
	var mutate_amount = randi_range(0,3)
	if Globals.coin_flip():
		diet["Meat"] -= mutate_amount
		diet["Plants"] += mutate_amount
	else:
		diet["Meat"] += mutate_amount
		diet["Plants"] -= mutate_amount

func test():
	diet.values()

#endregion

###############################################################################
## Private method
#region

#endregion



