package spigotpi

import "core:c"

MAX_DIGITS :: 256
MAX_BOXES :: 854

@(export)
spigotpi :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if length != 1 || input == nil || input[0] < 0 || input[0] > MAX_DIGITS do return -1
	digit_count := int(input[0])
	if output == nil || output_capacity < c.size_t(digit_count) do return -2
	if digit_count == 0 do return 0

	boxes := digit_count * 10 / 3
	remainders: [MAX_BOXES]i64
	for item := 0; item < boxes; item += 1 { remainders[item] = 2 }
	digits_held := 0
	for index := 0; index < digit_count; index += 1 {
		carried_over, sum: i64 = 0, 0
		cursor := boxes
		for cursor > 0 {
			cursor -= 1
			j := cursor
			remainders[j] *= 10
			sum = remainders[j] + carried_over
			denominator := i64(j * 2 + 1)
			quotient := sum / denominator
			remainders[j] = sum % denominator
			carried_over = quotient * i64(j)
		}
		remainders[0] = sum % 10
		q := sum / 10
		if q == 9 {
			digits_held += 1
		} else if q == 10 {
			q = 0
			for offset := 1; offset <= digits_held; offset += 1 {
				position := index - offset
				if output[position] == '9' do output[position] = '0'
				else do output[position] += 1
			}
			digits_held = 1
		} else {
			digits_held = 1
		}
		output[index] = u8('0' + q)
	}
	return i64(digit_count)
}
