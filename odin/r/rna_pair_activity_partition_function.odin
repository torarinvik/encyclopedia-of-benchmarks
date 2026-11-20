package rna_pair_activity_partition_function

import "core:c"

Max_Sequence_Length :: 16
Max_Parseable_Length :: 122

pair_input_index :: proc(n, left, right: int) -> int {
	preceding := left * (2*n - left - 1) / 2
	return 1 + preceding + (right - left - 1)
}

@(export)
rna_pair_activity_partition_function :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > Max_Parseable_Length do return -1
	n_value := input[0]
	if n_value < 0 || n_value > Max_Sequence_Length do return -1
	n := int(n_value)
	expected_length := 1 + n*(n-1)/2
	if length != c.size_t(expected_length) do return -1
	for index := 1; index < int(length); index += 1 {
		if input[index] < 0 || input[index] > 3 do return -1
	}
	if n == 0 do return 1

	table: [Max_Sequence_Length][Max_Sequence_Length]i64
	for i := 0; i < Max_Sequence_Length; i += 1 {
		for j := 0; j < Max_Sequence_Length; j += 1 { table[i][j] = 0 }
	}
	for span := 1; span <= n; span += 1 {
		for left := 0; left + span <= n; left += 1 {
			right := left + span - 1
			total: i64 = 1
			if left < right { total = table[left][right-1] }
			for partner := left; partner < right; partner += 1 {
				activity := input[pair_input_index(n, partner, right)]
				before: i64 = 1
				if partner > left { before = table[left][partner-1] }
				inside: i64 = 1
				if partner+1 < right { inside = table[partner+1][right-1] }
				total += before * inside * activity
			}
			table[left][right] = total
		}
	}
	return table[0][n-1]
}
