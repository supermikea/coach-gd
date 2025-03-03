extends HSplitContainer

func _ready():
	# Get the total width of the HSplitContainer
	var total_width = 648.0
	# print(total_width)

	# Set the split_offset to half of the total width, which will divide the container perfectly in the middle
	split_offset = int(total_width / 2)
	# print(split_offset)
