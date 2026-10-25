package tsvc_s4115_indexed_gather_product_sum

import "core:c"

// Clean-room bounded port of TSVC s4115; see package README for provenance.
MAX_N :: 64
MAX_VALUE :: i64(1_000_000)

@(export)
tsvc_s4115_indexed_gather_product_sum :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 4 || length > 193 do return -1
	n_raw := input[0]
	if n_raw < 1 || n_raw > MAX_N do return -1
	n := int(n_raw)
	if length != c.size_t(1 + 3 * n) do return -1

	for i := 0; i < n; i += 1 {
		index := input[1 + i]
		a_value := input[1 + n + i]
		b_value := input[1 + 2 * n + i]
		if index < 0 || index >= n_raw do return -1
		if a_value < 0 || a_value > MAX_VALUE || b_value < 0 || b_value > MAX_VALUE do return -1
	}

	total := i64(0)
	for i := 0; i < n; i += 1 {
		index := int(input[1 + i])
		total += input[1 + n + i] * input[1 + 2 * n + index]
	}
	return total
}
