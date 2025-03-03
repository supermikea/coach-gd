extends Control
# TODO handle errors
var process_id: int = 0
@onready var pop_up: = preload("res://error_popup.tscn")

func parse_assignments(input: String, allow_everythong: bool = false, use_denonator: bool = false) -> Array:
	var assignments := []
	var lines := input.strip_edges().split("\n")
	
	for line in lines:
		# Skip empty lines.
		if line.strip_edges() == "":
			continue
		
		var parts = [""]
		var denonator = ""
		# check if lines contain a conditional operator REALLY needs case/match stuff
		if line.contains(">="):
			parts = line.split(">=")
			denonator = ">="
		elif line.contains("=>"):
			parts = line.split("=>")
			denonator = "=>"
		elif line.contains(">"):
			parts = line.split(">")
			denonator = ">"
		elif line.contains("<"):
			parts = line.split("<")
			denonator = "<"
		elif line.contains("<="):
			parts = line.split("<=")
			denonator = "<="
		elif line.contains("=<"):
			parts = line.split("=<")
			denonator = "=<"
		else:
			parts = line.split("=")
			denonator = "="
		
		# If no '=' is found, assume the whole line is a key with a null value.
		if parts.size() == 1:
			assignments.append({"key": parts[0].strip_edges(), "value": null})
		
		elif parts.size() == 2:
			var key = parts[0].strip_edges()
			var value_str = parts[1].strip_edges()
			var value = null  # Default to null if no value is found

			if value_str == "":
				value = null
			elif value_str.is_valid_float():
				# If the value is a valid number, convert it to float or int
				value = value_str.to_float() if value_str.find(".") != -1 else value_str.to_float() # dirty hack FIXME
			else:
				# If it's not a number, either allow the raw expression or flag an error.
				if allow_everythong:
					value = value_str
				else:
					push_error("Invalid value for key '%s': '%s'" % [key, value_str])
					return []  # Return an empty array on error
			if use_denonator:
				return [key, denonator, value]
			else:
				assignments.append({"key": key, "value": value})
		
		else:
			# Reject lines with multiple '=' signs.
			push_error("Invalid syntax for line: '%s'" % line)
			return []
	
	return assignments

func save_to_file(location: String, content):
	var file = FileAccess.open("user://%s.dat" % location, FileAccess.WRITE)
	file.store_string(content)

func load_from_file(location: String):
	var file = FileAccess.open("user://%s.dat" % location, FileAccess.READ)
	if file == null:
		return
	var content = file.get_as_text()
	return content

func _ready() -> void:
	# loading of everything
	var formulatext = load_from_file("textformula")
	if formulatext:
		%"TextEdit-Formula".text = formulatext
	var textvars = load_from_file("textvars")
	if textvars:
		%"TextEdit-Vars".text = textvars
	var textcondition = load_from_file("textcondition")
	if textcondition:
		%"TextEdit-Condition".text = textcondition

func _on_text_edit_formula_text_changed() -> void:
	var node: TextEdit = %"TextEdit-Formula"
	var text = node.text
	save_to_file("textformula", text)

func _on_text_edit_vars_text_changed() -> void:
	var node: TextEdit = %"TextEdit-Vars"
	var text = node.text
	save_to_file("textvars", text)

func _on_text_edit_condition_text_changed() -> void:
	var node: TextEdit = %"TextEdit-Condition"
	var text = node.text
	save_to_file("textcondition", text)

# Checks a condition of the form [VARIABLE, operator, VALUE] on the current state.
func check_condition(state: Dictionary, condition: Array) -> bool:
	if condition.size() != 3:
		push_error("Condition must be in the form [VARIABLE, operator, VALUE]")
		return false
	
	var variable = condition[0]
	var op = condition[1]
	var target_value = condition[2]

	if not state.has(variable): # cursed, this is expected for the first thingie, FIXME
		# push_error("Variable '%s' not found in state." % variable)
		# push_error("STATE: %s" % state)
		return false

	var current_value = state[variable]
	target_value = float(target_value)
	if not current_value:
		return false
	match op:
		"=":
			return current_value == target_value
		">=":
			return current_value >= target_value
		"=>":
			return current_value >= target_value
		">":
			# print(current_value)
			# print(target_value)
			# print(type_string(typeof(target_value)))
			return current_value > target_value
		"<":
			return current_value < target_value
		"<=":
			return current_value <= target_value
		"=<":
			return current_value <= target_value
		_:
			push_error("Invalid operator in condition: %s" % op)
			return false

func evaluate(command, variable_names = [], variable_values = []):
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return

	var result = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		return result

func plot_graph(final_states: Array, x_axis: String, y_axis: String):
	# Convert the array to a JSON string
	var json_data = JSON.stringify(final_states)
	
	# Define a temporary file path
	var json_file_path = "user://graph_data.json"
	
	# Write JSON to the file
	var file = FileAccess.open(json_file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()
	else:
		print("Error: Could not write to JSON file")
		return
	
	# Path to your Python script
	var script_path = ProjectSettings.globalize_path("res://mygraph.py")
	# Change to "python" if needed
	var python_exe = ProjectSettings.globalize_path(".venv/bin/python3")
	
	# print(ProjectSettings.globalize_path(json_file_path))
	
	# Build the argument list
	var args = [script_path, ProjectSettings.globalize_path(json_file_path), x_axis, y_axis]
	

	
	# Execute the Python script
	process_id = OS.create_process(python_exe, args)
	
	# Start monitoring output
	if process_id:
		print_debug("Python script started with PID:", process_id)
		set_process(true)  # Enables _process() function

func _process(_delta):
	if process_id:
		# Check if the process has finished
		var status = OS.get_process_exit_code(process_id)
		if status != -1:  # -1 means still running
			print_debug("Python script exited with code:", status)
			process_id = 0
			set_process(false)  # Stop _process() loop

func loop_until_target(formula_array: Array, vars_array: Array, condition: Array, max_iterations: int = 1000) -> Array:
	# Build the state dictionary from the initial variables array.
	var state := {}
	for assignment in vars_array:
		state[assignment["key"]] = assignment["value"]
	
	var iteration = 0
	var iteration_details = []
	while iteration < max_iterations:

		# Check if the condition is met.
		if check_condition(state, condition):
			# print("Condition met after %d iterations: %s" % [iteration, state])
			break
		
		iteration += 1
		
		# Process each formula in the array.
		# For formulas that do not reference their own key, only evaluate on the first iteration.
		for assignment in formula_array:
			var key = assignment["key"]
			var formula_str = str(assignment["value"])
			
			#if iteration > 1 and formula_str.find(key) == -1:
			#	continue

			# Build arrays for evaluating the formula from the current state.
			var var_names = []
			var var_values = []
			for k in state.keys():
				var_names.append(k)
				var_values.append(state[k])
			
			# Evaluate the formula expression.
			var new_value = evaluate(formula_str, var_names, var_values)
			# print(new_value)
			state[key] = new_value
			# print(state)
		# print("Iteration %d: %s" % [iteration, state])
		iteration_details.append(state.duplicate())
	
	return [state, iteration_details]

func _on_mikeiscool_pressed() -> void: # here we need to create a popup with the graph
	# setup variables
	var textvars = load_from_file("textvars")
	var formulavars = load_from_file("textformula")
	var textcondition = load_from_file("textcondition")
	var dictvars = parse_assignments(textvars)
	var dictformula = parse_assignments(formulavars, true)
	var dictcondition = parse_assignments(textcondition, true, true)
	# print(dictvars)
	# print(dictformula)
	# print(dictcondition)
	
	# graph settings
	var Xaxis: = "X"
	var Yaxis: = "Y"
	if %"X-axis".text:
		Xaxis = %"X-axis".text
	
	if %"Y-axis".text:
		Yaxis = %"Y-axis".text
	
	# check if graph settings are fine TODO, check earlier
	var xaxis_passed = false
	var yaxis_passed = false
	for item in dictvars:
		print(item["key"])
		if item["key"] == Xaxis:
			xaxis_passed = true
		if item["key"] == Yaxis:
			yaxis_passed = true
	for item in dictformula:
		print(item["key"])
		if item["key"] == Xaxis:
			xaxis_passed = true
		if item["key"] == Yaxis:
			yaxis_passed = true
	
	if not xaxis_passed or not yaxis_passed:
		var error_msg = ""
		if not xaxis_passed:
			error_msg = "X-axis variable not correct!"
		elif not yaxis_passed: 
			error_msg = "Y-axis variable not correct!"
		var popup = pop_up.instantiate()
		add_child(popup)
		popup.get_child(0).get_child(1).text = error_msg
		return
	
	# print(dictformula)
	# print(evaluate('A * B',['A', 'B'], [10, 30])) gives 300
	var iterations := loop_until_target(dictformula, dictvars, dictcondition)
	# print_debug(iterations[0])
	
	call_deferred("plot_graph", iterations[1], Xaxis, Yaxis)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		print_debug("Exiting...")
		if process_id != 0:
			OS.kill(process_id)
		get_tree().quit() # default behavior
