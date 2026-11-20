package zhouge_summatory_multiplicative_function

import "core:c"

Modulus :: i64(469_762_049)
Max_N :: i64(10_000_000)

floor_sqrt :: proc "contextless" (value: i64) -> i64 {
	low, high := i64(1), i64(3162)
	for low < high {
		middle := low + (high - low + 1) / 2
		if middle <= value / middle { low = middle } else { high = middle - 1 }
	}
	return low
}

normalize :: proc "contextless" (value: i64) -> i64 {
	remainder := value % Modulus
	if remainder < 0 { return remainder + Modulus }
	return remainder
}

quotient_at :: proc "contextless" (index: int, n: i64, high_count, size: int) -> i64 {
	if index < high_count { return n / i64(index) }
	return i64(size - index)
}

value_index :: proc "contextless" (value, n, root: i64, size: int) -> int {
	if value <= root { return size - int(value) }
	return int(n / value)
}

upper_bound :: proc "contextless" (primes: []i64, value: i64) -> int {
	low, high := 0, len(primes)
	for low < high {
		middle := low + (high - low) / 2
		if primes[middle] <= value { low = middle + 1 } else { high = middle }
	}
	return low
}

apply_skipped_prime_range :: proc "contextless" (index, stage: int,
		small_lo, small_hi: []u32, simple_cursor: []u32,
		prefix_g: []i64, smooth_sum: []i64) {
	next := u32(stage + 1)
	if next < small_lo[index] { next = small_lo[index] }
	if next > small_hi[index] { next = small_hi[index] }
	old := simple_cursor[index]
	if next < old {
		smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[int(old)] - prefix_g[int(next)])
		simple_cursor[index] = next
	}
}

apply_skipped_power_sums :: proc "contextless" (index, stage: int,
		small_lo, small_hi: []u32, g_cursor: []u32,
		prefix_sum, g_zero, g_one: []i64) {
	next := u32(stage)
	if next < small_lo[index] { next = small_lo[index] }
	if next > small_hi[index] { next = small_hi[index] }
	old := g_cursor[index]
	if next > old {
		g_zero[index] = normalize(g_zero[index] - i64(next - old))
		g_one[index] = normalize(g_one[index] - (prefix_sum[int(next)] - prefix_sum[int(old)]))
		g_cursor[index] = next
	}
}

small_value :: proc "contextless" (value: i64, smallest: []u32, a, b: i64) -> i64 {
	remaining := value
	result := i64(1)
	for remaining > 1 {
		prime := i64(smallest[int(remaining)])
		exponent := i64(0)
		for remaining % prime == 0 {
			remaining /= prime
			exponent += 1
		}
		result = result * ((a * exponent + b * prime) % Modulus) % Modulus
	}
	return result
}

solve :: proc "contextless" (n, a, b: i64) -> i64 {
	root := floor_sqrt(n)
	high_count := int(n / root)
	for high_count > 1 && n / i64(high_count - 1) == root { high_count -= 1 }
	size := high_count + int(root)

	smallest := make([]u32, int(root)+1); defer delete(smallest)
	primes := make([dynamic]i64); defer delete(primes)
	for value := i64(2); value <= root; value += 1 {
		if smallest[int(value)] != 0 { continue }
		smallest[int(value)] = u32(value)
		append(&primes, value)
		if value <= root/value {
			for multiple := value*value; multiple <= root; multiple += value {
				if smallest[int(multiple)] == 0 { smallest[int(multiple)] = u32(value) }
			}
		}
	}

	prefix_sum := make([]i64, len(primes)+1); defer delete(prefix_sum)
	prefix_g := make([]i64, len(primes)+1); defer delete(prefix_g)
	for index in 0..<len(primes) {
		prefix_sum[index+1] = normalize(prefix_sum[index] + primes[index])
		prefix_g[index+1] = normalize(prefix_g[index] + a + b*primes[index])
	}

	g_zero := make([]i64, size); defer delete(g_zero)
	g_one := make([]i64, size); defer delete(g_one)
	smooth_sum := make([]i64, size); defer delete(smooth_sum)
	small_lo := make([]u32, size); defer delete(small_lo)
	small_hi := make([]u32, size); defer delete(small_hi)
	simple_cursor := make([]u32, size); defer delete(simple_cursor)
	g_cursor := make([]u32, size); defer delete(g_cursor)
	for index in 1..<size {
		value := quotient_at(index, n, high_count, size)
		small_lo[index] = u32(upper_bound(primes[:], floor_sqrt(value)))
		small_hi[index] = u32(upper_bound(primes[:], value))
		simple_cursor[index] = small_hi[index]
		g_cursor[index] = small_lo[index]
		g_zero[index] = value % Modulus
		left, right := value, value+1
		if (left & 1) == 0 { left /= 2 } else { right /= 2 }
		g_one[index] = (left % Modulus) * (right % Modulus) % Modulus
		smooth_sum[index] = 1
	}

	for stage in 0..<len(primes) {
		prime := primes[stage]
		square := prime*prime
		for index in 1..<size {
			value := quotient_at(index, n, high_count, size)
			if value < square { break }
			child := value_index(value/prime, n, root, size)
			apply_skipped_power_sums(child, stage, small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one)
			g_zero[index] = normalize(g_zero[index] - g_zero[child])
			g_one[index] = normalize(g_one[index] - prime*g_one[child])
		}
	}
	for index in 1..<size {
		apply_skipped_power_sums(index, len(primes), small_lo, small_hi, g_cursor, prefix_sum, g_zero, g_one)
	}

	for stage := len(primes)-1; stage >= 0; stage -= 1 {
		prime := primes[stage]
		square := prime*prime
		for index in 1..<size {
			value := quotient_at(index, n, high_count, size)
			if value < square { break }
			apply_skipped_prime_range(index, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum)
			power, exponent := prime, i64(1)
			for power <= value {
				child := value_index(value/power, n, root, size)
				apply_skipped_prime_range(child, stage, small_lo, small_hi, simple_cursor, prefix_g, smooth_sum)
				local := (a*exponent + b*prime) % Modulus
				smooth_sum[index] = normalize(smooth_sum[index] + local*smooth_sum[child])
				power *= prime
				exponent += 1
			}
		}
	}

	answer := smooth_sum[1]
	for value := i64(1); value <= root; value += 1 {
		quotient_index := value_index(n/value, n, root, size)
		large_prime_sum := normalize(a*normalize(g_zero[quotient_index]-1) + b*normalize(g_one[quotient_index]-1))
		answer = normalize(answer + small_value(value, smallest, a, b)*large_prime_sum)
	}
	return answer
}

@(export)
zhouge_summatory_multiplicative_function :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	n, a, b := input[0], input[1], input[2]
	if n < 1 || n > Max_N || a < 0 || a >= Modulus || b < 0 || b >= Modulus do return -1
	return solve(n, a, b)
}
