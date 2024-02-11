class_name Scent
extends Node

# Scent: Species, Age, Sex, isPregnant, 
var species
var age = 0
var isFemale = true
var isPregnant = false
var strength = 10


func _init(_age, _isFemale, _isPregnant):
	age = _age
	isFemale = _isFemale
	isPregnant = _isPregnant 
