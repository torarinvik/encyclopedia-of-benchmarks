module fibonacci_integer_code

@[export: 'fibonacci_integer_code']
pub fn fibonacci_integer_code(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 2 || length > 33 { return -1 }
	unsafe {
		n0 := input[0]
		if n0 < 1 || n0 > 32 || length != usize(n0 + 1) { return -1 }
		n := int(n0)
		for i in 0 .. n { if input[i+1] < 0 || input[i+1] > 1000000 { return -1 } }
		mut fib := []u64{len: 30, init: 0}; fib[0] = 1; fib[1] = 2
		mut fib_count := 2
		for fib_count < 30 && fib[fib_count-1] + fib[fib_count-2] <= 1000001 {
			fib[fib_count] = fib[fib_count-1] + fib[fib_count-2]; fib_count++
		}
		mut staged := []u8{len: 960, init: 0}
		mut out := 0
		for v in 0 .. n {
			mut remaining := u64(input[v+1] + 1)
			mut top := 0
			for top+1 < fib_count && fib[top+1] <= remaining { top++ }
			mut bits := []u8{len: 30, init: 0}
			mut j := top + 1
			for j > 0 {
				j--
				if fib[j] <= remaining { bits[j] = 1; remaining -= fib[j] }
			}
			for i in 0 .. top+1 { staged[out] = u8(48) + bits[i]; out++ }
			staged[out] = 49; out++
		}
		if output == nil || capacity < usize(out) { return -2 }
		for i in 0 .. out { output[i] = staged[i] }
		return i64(out)
	}
}
