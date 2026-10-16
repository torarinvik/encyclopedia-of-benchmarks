module car_pool

@[export: 'car_pool']
pub fn car_pool(input &i64, length usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 194 { return -1 }
	unsafe {
		if input[0] < 0 || input[0] > 1000 || input[1] < 0 || input[1] > 64 { return -1 }
		capacity := i32(input[0])
		trip_count := int(input[1])
		if int(length) != 2 + 3 * trip_count { return -1 }

		mut events := [1001]i32{}
		for trip in 0 .. trip_count {
			offset := 2 + 3 * trip
			passengers := input[offset]
			origin := input[offset + 1]
			destination := input[offset + 2]
			if passengers < 1 || passengers > 1000 || origin < 0 || origin >= destination || destination > 1000 {
				return -1
			}
			events[int(origin)] += i32(passengers)
			events[int(destination)] -= i32(passengers)
		}

		mut occupants := i32(0)
		for position in 0 .. 1000 {
			occupants += events[position]
			if occupants > capacity { return 0 }
		}
		return 1
	}
}
