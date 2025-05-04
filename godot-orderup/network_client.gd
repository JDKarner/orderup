extends Node

var station_id = "01" # This will be 01 through 40
var server_url = "http://localhost:17076" # Replace with your server's IP
var update_timer = 0.0
var update_interval = 5.0 # Check for updates every 5 seconds

# Current display data
var current_data = {
	"order_number": "",
	"os_version": "",
	"notes": ""
}

func _ready():
	print("Starting application...")
	load_config()
	fetch_station_data()

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		fetch_station_data()

func load_config():
	var config_file = "user://station_config.json"
	var file = FileAccess.open(config_file, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		file.close()
		if error == OK:
			var data = json.get_data()
			if data.has("station_id"):
				station_id = data.station_id
				print("Loaded station_id: ", station_id)
	else:
		# Create default config
		var config_data = { "station_id": station_id }
		file = FileAccess.open(config_file, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(config_data, "  "))
			file.close()

func fetch_station_data():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_data_received)
	var url = server_url + "/station/" + station_id
	print("Fetching data from: ", url)
	
	# Add error handling for the request
	var error = http.request(url)
	if error != OK:
		print("HTTP Request failed with error: ", error)
		http.queue_free()

func _on_data_received(result, response_code, headers, body):
	print("HTTP Response - Result: ", result, " Code: ", response_code)
	
	if result != HTTPRequest.RESULT_SUCCESS:
		print("HTTP Request failed with result: ", result)
		return
		
	if response_code != 200:
		print("HTTP Request failed with response code: ", response_code)
		return
		
	if body.size() == 0:
		print("Received empty response")
		return
		
	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())
	
	if parse_result != OK:
		print("JSON Parse Error: ", json.get_error_message())
		print("Raw response: ", body.get_string_from_utf8())
		return
		
	var data = json.get_data()
	print("Received data: ", data)
	
	if data != current_data:
		current_data = data
		update_ui(data)
	
	# Clean up the HTTPRequest node
	var http = get_node_or_null("HTTPRequest")
	if http:
		http.queue_free()

func update_ui(data):
	var order_num = $OrderNum
	var os_ver = $OSVer
	var notes = $Notes

	if !order_num or !os_ver or !notes:
		print("Error: UI nodes not found!")
		print("OrderNum exists: ", is_instance_valid(order_num))
		print("OSVer exists: ", is_instance_valid(os_ver))
		print("Notes exists: ", is_instance_valid(notes))
		return

	print("Updating UI with data: ", data)
	if data.has("order_number"):
		order_num.text = "[font_size={76}][b]Order #: " + str(data.order_number) + "[/b][/font_size]"
	if data.has("os_version"):
		os_ver.text = "[i]OS Version: " + str(data.os_version) + "[/i]"
	if data.has("notes"):
		notes.text = "[code] Notes:" + str(data.notes) + "[/code]"
	print("UI update complete")
