module lucky_number

const max_input = i64(1_000_000)

// Preserve the pinned Java rank loop, including counter += 1 each round.
@[export: 'lucky_number']
pub fn lucky_number(number i64) i64 {
	if number < 1 || number > max_input { return -1 }
	mut counter := i64(2)
	mut position := number
	for counter <= position {
		if position % counter == 0 { return 0 }
		position -= position / counter
		counter++
	}
	return 1
}
