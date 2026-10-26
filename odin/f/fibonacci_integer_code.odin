package fibonacci_integer_code

import "core:c"

fibonacci_integer_code :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 33 do return -1
	n0 := input[0]
	if n0 < 1 || n0 > 32 || length != c.size_t(n0+1) do return -1
	n := int(n0)
	for i := 0; i < n; i += 1 { if input[i+1] < 0 || input[i+1] > 1000000 do return -1 }
	fib: [30]u64; fib[0] = 1; fib[1] = 2
	fib_count := 2
	for fib_count < 30 && fib[fib_count-1] + fib[fib_count-2] <= 1000001 {
		fib[fib_count] = fib[fib_count-1] + fib[fib_count-2]; fib_count += 1
	}
	staged: [960]u8
	out := 0
	for v := 0; v < n; v += 1 {
		remaining := u64(input[v+1] + 1)
		top := 0
		for top+1 < fib_count && fib[top+1] <= remaining { top += 1 }
		bits: [30]u8
		for j := top+1; j > 0; {
			j -= 1
			if fib[j] <= remaining { bits[j] = 1; remaining -= fib[j] }
		}
		for i := 0; i <= top; i += 1 { staged[out] = 48 + bits[i]; out += 1 }
		staged[out] = 49; out += 1
	}
	if output == nil || capacity < c.size_t(out) do return -2
	for i := 0; i < out; i += 1 { output[i] = staged[i] }
	return i64(out)
}
