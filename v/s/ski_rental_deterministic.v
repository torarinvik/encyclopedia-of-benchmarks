module ski_rental_deterministic

const max_input = 4
const max_trips = 32

@[export: 'ski_rental_deterministic']
pub fn ski_rental_deterministic(input &i64, length usize, output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 3 || length > max_input { return -1 }
		rent, purchase, trips := input[0], input[1], input[2]
		if length != 3 || rent < 1 || rent > 32 || purchase < 1 || purchase > 64 || trips < 0 || trips > max_trips { return -1 }
		count := int(trips)
		if output == nil || capacity < count { return -2 }
		mut actions := []u8{len: max_trips, init: 0}
		threshold := purchase / rent
		for trip in 0 .. count {
			if i64(trip) < threshold { actions[trip] = 0 }
			else if i64(trip) == threshold { actions[trip] = 1 }
			else { actions[trip] = 2 }
		}
		for trip in 0 .. count { output[trip] = actions[trip] }
		return i64(count)
	}
}
