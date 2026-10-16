package permutation_and_combination

import "core:c"

@(export)
permutation_and_combination :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n != 3 do return -1
	op, a, r := v[0], v[1], v[2]
	if op < 0 || op > 2 || a < 0 || a > 18 do return -1
	if op != 0 && (r < 0 || r > a) do return -1
	result := i64(1)
	if op == 0 { for i := i64(2); i <= a; i += 1 { result *= i } }
	else if op == 1 { for i := a - r + 1; i <= a; i += 1 { result *= i } }
	else {
		k := r; if k > a - k do k = a - k
		for i := i64(1); i <= k; i += 1 { result = result * (a - k + i) / i }
	}
	return result
}
