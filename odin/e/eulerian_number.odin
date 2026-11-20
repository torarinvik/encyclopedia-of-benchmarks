package eulerian_number

import "core:c"

@(export)
eulerian_number :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
	if values == nil || length != 2 do return -1
	n, target := values[0], values[1]
	if n < 0 || n > 20 || target < 0 ||
	   (n == 0 && target != 0) || (n > 0 && target >= n) do return -1

	previous: [21]i64 = {}
	current: [21]i64 = {}
	previous[0] = 1
	for row := 1; row <= int(n); row += 1 {
		for k := 0; k < row; k += 1 {
			same := previous[k]
			fewer: i64 = 0
			if k > 0 do fewer = previous[k - 1]
			current[k] = (i64(k) + 1) * same + (i64(row) - i64(k)) * fewer
		}
		for index := 0; index < 21; index += 1 {
			previous[index] = current[index]
			current[index] = 0
		}
	}
	return previous[int(target)]
}
