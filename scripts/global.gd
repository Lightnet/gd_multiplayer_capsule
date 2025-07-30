extends Node
# place holder...

func _ready():
	## Generate a single random name
	#var name = generate_random_name()
	#print(name)  # Outputs something like "Kivora"
	#
	## Generate name with custom length range
	#var long_name = generate_random_name(6, 12)
	#print(long_name)  # Outputs something like "Saterinu"
	#
	## Generate multiple names
	#for i in range(5):
		#print(generate_random_name(4, 6))  # Outputs 5 names like "Tavo", "Riney", etc.
	pass

func generate_random_name(min_length: int = 3, max_length: int = 8) -> String:
	var vowels = ["a", "e", "i", "o", "u"]
	var consonants = ["b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "r", "s", "t", "v", "w", "y"]
	var name_length = randi_range(min_length, max_length)
	var name = ""
	var use_vowel = randi() % 2 == 0
	
	for i in range(name_length):
		if use_vowel:
			name += vowels[randi() % vowels.size()]
		else:
			name += consonants[randi() % consonants.size()]
		use_vowel = !use_vowel
	
	# Capitalize first letter
	name = name.capitalize()
	
	return name
