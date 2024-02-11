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

#endregion

## Exported variables
#region
# Diet variables should sum to 10
@export var meat = 5
@export var plants = 5

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
		meat -= mutate_amount
		plants += mutate_amount
	else:
		meat += mutate_amount
		plants -= mutate_amount

#endregion

###############################################################################
## Private method
#region

#endregion



