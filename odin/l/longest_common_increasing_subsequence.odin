package longest_common_increasing_subsequence

import "core:c"

MAX_INPUT_LENGTH :: 67

@(export)
longest_common_increasing_subsequence :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
	n := input[0]
	m := input[1]
	if n < 0 || n > 32 || m < 0 || m > 32 do return -1
	if length != c.size_t(2 + n + m) do return -1
	for index := c.size_t(0); index < c.size_t(n + m); index += 1 {
		if input[2 + index] < -16 || input[2 + index] > 16 do return -1
	}

	ending_at: [32]i64
	for index := 0; index < 32; index += 1 { ending_at[index] = 0 }
	for i := 0; i < int(n); i += 1 {
		value := input[2 + c.size_t(i)]
		best_smaller := i64(0)
		for j := 0; j < int(m); j += 1 {
			other := input[2 + c.size_t(n) + c.size_t(j)]
			if value > other {
				if ending_at[j] > best_smaller do best_smaller = ending_at[j]
			} else if value == other && best_smaller + 1 > ending_at[j] {
				ending_at[j] = best_smaller + 1
			}
		}
	}
	answer := i64(0)
	for j := 0; j < int(m); j += 1 { if ending_at[j] > answer do answer = ending_at[j] }
	return answer
}
