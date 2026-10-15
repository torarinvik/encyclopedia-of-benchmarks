module main

@[export: 'distance_between_bus_stops']
pub fn distance_between_bus_stops(input &i64, length usize) i64 {
	unsafe {
		if length < 3 || length > 66 {
			return -1
		}
		stop_count := length - 2
		start_value := input[0]
		destination_value := input[1]
		if start_value < 0 || destination_value < 0 ||
			start_value >= i64(stop_count) || destination_value >= i64(stop_count) {
			return -1
		}
		start := int(start_value)
		destination := int(destination_value)
		low := if start < destination { start } else { destination }
		high := if start < destination { destination } else { start }
		mut total := i64(0)
		mut direct := i64(0)
		for index in 0 .. int(stop_count) {
			distance := input[index + 2]
			if distance < 0 || distance > 1000000 {
				return -1
			}
			total += distance
			if index >= low && index < high {
				direct += distance
			}
		}
		other := total - direct
		return if direct < other { direct } else { other }
	}
}
