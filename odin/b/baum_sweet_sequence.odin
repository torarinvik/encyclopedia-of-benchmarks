package baum_sweet_sequence

import "core:c"

baum_sweet_term :: proc(number: i64) -> i64 {
	if number == 0 do return 0
	mask := i64(1)
	for mask <= number / 2 { mask *= 2 }
	odd_zero_run := false
	for mask > 0 {
		if (number & mask) != 0 {
			if odd_zero_run do return 0
			odd_zero_run = false
		} else {
			odd_zero_run = !odd_zero_run
		}
		mask /= 2
	}
	return if odd_zero_run then 0 else 1
}

@(export)
baum_sweet_sequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 1 do return -1
	count := input[0]
	if count < 0 || count > 63 do return -1
	packed := i64(0)
	bit := i64(1)
	for index := 0; index < int(count); index += 1 {
		if baum_sweet_term(i64(index)) != 0 do packed += bit
		if index + 1 < int(count) do bit *= 2
	}
	return packed
}
