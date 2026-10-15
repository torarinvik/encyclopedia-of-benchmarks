package lucky_number

MAX_INPUT :: i64(1_000_000)

// Preserve the pinned Java rank loop, including counter += 1 each round.
@(export)
lucky_number :: proc "c" (number: i64) -> i64 {
	if number < 1 || number > MAX_INPUT do return -1
	counter := i64(2)
	position := number
	for counter <= position {
		if position % counter == 0 do return 0
		position -= position / counter
		counter += 1
	}
	return 1
}
