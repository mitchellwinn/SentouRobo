extends Node

var indexedCategories: Array
var head: Array
var upperTorso: Array
var shoulders: Array
var arms: Array
var weapons: Array
var lowerTorso: Array
var thighs: Array
var legs: Array
var feet: Array
var backFire: Array

# Called when the node enters the scene tree for the first time.
func _ready():
	
	weapons.append(Weapon.new("Needle Cannon","","NeedleCannon","gun",3,true,30,20,0))
	weapons.append(Weapon.new("Heaven's Spine","","Drill","melee",2,true,20,50,200))
	
	backFire.append(Weapon.new("Scatter Launch","","Mech1","missile",9,false,20,20,20))
	backFire.append(Weapon.new("Laser Cannon","","Mech2","laser",5,true,40,40,100))
	
	head.append(Part.new("Dragonfly","Mech1","armor", 2))
	head.append(Part.new("Sentinel 1","Mech2","armor", 3))
	
	upperTorso.append(Part.new("Form","Mech1","armor", 5))
	upperTorso.append(Part.new("Coil","Mech2","armor", 4))
	
	shoulders.append(Part.new("Mercenary","Mech1","armor", 3))
	shoulders.append(Part.new("Coil","Mech2","armor", 2))
	
	arms.append(Part.new("Plated","Mech1","armor", 3))
	arms.append(Part.new("Marksman","Mech2","armor", 1))
	
	lowerTorso.append(Part.new("Joust","Mech1","armor", 3))
	lowerTorso.append(Part.new("Coil","Mech2","armor", 1))
	
	thighs.append(Part.new("Plated","Mech1","armor", 4))
	thighs.append(Part.new("Coil","Mech2","armor", 2))
	
	legs.append(Part.new("Form","Mech1","armor", 3))
	legs.append(Part.new("Titanium Blade","Mech2","armor", 2))
	
	feet.append(Part.new("Form","Mech1","armor", 2))
	feet.append(Part.new("Titanium Blade","Mech2","armor", 3)) 
	
	indexedCategories.append(head)
	indexedCategories.append(upperTorso)
	indexedCategories.append(shoulders)
	indexedCategories.append(arms)
	indexedCategories.append(weapons)
	indexedCategories.append(weapons)
	indexedCategories.append(lowerTorso)
	indexedCategories.append(thighs)
	indexedCategories.append(legs)
	indexedCategories.append(feet)
	indexedCategories.append(backFire)
	indexedCategories.append(backFire)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
