module zhouge_summatory_multiplicative_function

const modulus = i64(469_762_049)
const max_n = i64(10_000_000)

fn floor_sqrt(value i64) i64 {
	mut low := i64(1)
	mut high := i64(3162)
	for low < high {
		middle := low + (high - low + 1) / 2
		if middle <= value / middle { low = middle } else { high = middle - 1 }
	}
	return low
}

fn normalize(value i64) i64 {
	mut remainder := value % modulus
	if remainder < 0 { remainder += modulus }
	return remainder
}

fn quotient_at(index int, n i64, high_count int, size int) i64 {
	if index < high_count { return n / i64(index) }
	return i64(size - index)
}

fn value_index(value i64, n i64, root i64, size int) int {
	if value <= root { return size - int(value) }
	return int(n / value)
}

fn upper_bound(primes []i64, value i64) int {
	mut low := 0
	mut high := primes.len
	for low < high {
		middle := low + (high - low) / 2
		if primes[middle] <= value { low = middle + 1 } else { high = middle }
	}
	return low
}

fn apply_skipped_prime_range(index int, stage int, small_lo []u32, small_hi []u32,
	mut simple_cursor []u32, prefix_g []i64, mut smooth_sum []i64) {
	mut next := u32(stage + 1)
	if next < small_lo[index] { next = small_lo[index] }
	if next > small_hi[index] { next = small_hi[index] }
	old := simple_cursor[index]
	if next < old {
		smooth_sum[index] = normalize(smooth_sum[index] + prefix_g[int(old)] - prefix_g[int(next)])
		simple_cursor[index] = next
	}
}

fn apply_skipped_power_sums(index int, stage int, small_lo []u32, small_hi []u32,
	mut g_cursor []u32, prefix_sum []i64, mut g_zero []i64, mut g_one []i64) {
	mut next := u32(stage)
	if next < small_lo[index] { next = small_lo[index] }
	if next > small_hi[index] { next = small_hi[index] }
	old := g_cursor[index]
	if next > old {
		g_zero[index] = normalize(g_zero[index] - i64(next - old))
		g_one[index] = normalize(g_one[index] - (prefix_sum[int(next)] - prefix_sum[int(old)]))
		g_cursor[index] = next
	}
}

fn small_value(value i64, smallest []u32, a i64, b i64) i64 {
	mut remaining := value
	mut result := i64(1)
	for remaining > 1 {
		prime := i64(smallest[int(remaining)])
		mut exponent := i64(0)
		for remaining % prime == 0 {
			remaining /= prime
			exponent++
		}
		result = result * ((a * exponent + b * prime) % modulus) % modulus
	}
	return result
}

fn solve(n i64, a i64, b i64) i64 {
	root := floor_sqrt(n)
	mut high_count := int(n / root)
	for high_count > 1 && n / i64(high_count - 1) == root { high_count-- }
	size := high_count + int(root)
	mut smallest := []u32{len: int(root) + 1, init: 0}
	mut primes := []i64{}
	value := i64(2)
	for value <= root {
		if smallest[int(value)] != 0 { value++; continue }
		smallest[int(value)] = u32(value)
		primes << value
		if value <= root / value {
			mut multiple := value * value
			for multiple <= root {
				if smallest[int(multiple)] == 0 { smallest[int(multiple)] = u32(value) }
				multiple += value
			}
		}
		value++
	}
	mut prefix_sum := []i64{len: primes.len + 1, init: 0}
	mut prefix_g := []i64{len: primes.len + 1, init: 0}
	for index, prime in primes {
		prefix_sum[index + 1] = normalize(prefix_sum[index] + prime)
		prefix_g[index + 1] = normalize(prefix_g[index] + a + b * prime)
	}
	mut g_zero := []i64{len: size, init: 0}
	mut g_one := []i64{len: size, init: 0}
	mut smooth_sum := []i64{len: size, init: 1}
	mut small_lo := []u32{len: size, init: 0}
	mut small_hi := []u32{len: size, init: 0}
	mut simple_cursor := []u32{len: size, init: 0}
	mut g_cursor := []u32{len: size, init: 0}
	for index in 1 .. size {
		y := quotient_at(index, n, high_count, size)
		small_lo[index] = u32(upper_bound(primes, floor_sqrt(y)))
		small_hi[index] = u32(upper_bound(primes, y))
		simple_cursor[index] = small_hi[index]
		g_cursor[index] = small_lo[index]
		g_zero[index] = y % modulus
		mut left := y
		mut right := y + 1
		if left & 1 == 0 { left /= 2 } else { right /= 2 }
		g_one[index] = (left % modulus) * (right % modulus) % modulus
	}
	for stage, prime in primes {
		square := prime * prime
		for index in 1 .. size {
			y := quotient_at(index, n, high_count, size)
			if y < square { break }
			child := value_index(y / prime, n, root, size)
			apply_skipped_power_sums(child, stage, small_lo, small_hi, mut g_cursor, prefix_sum, mut g_zero, mut g_one)
			g_zero[index] = normalize(g_zero[index] - g_zero[child])
			g_one[index] = normalize(g_one[index] - prime * g_one[child])
		}
	}
	for index in 1 .. size {
		apply_skipped_power_sums(index, primes.len, small_lo, small_hi, mut g_cursor, prefix_sum, mut g_zero, mut g_one)
	}
	mut position := primes.len
	for position > 0 {
		position--
		prime := primes[position]
		square := prime * prime
		for index in 1 .. size {
			y := quotient_at(index, n, high_count, size)
			if y < square { break }
			apply_skipped_prime_range(index, position, small_lo, small_hi, mut simple_cursor, prefix_g, mut smooth_sum)
			mut power := prime
			mut exponent := i64(1)
			for power <= y {
				child := value_index(y / power, n, root, size)
				apply_skipped_prime_range(child, position, small_lo, small_hi, mut simple_cursor, prefix_g, mut smooth_sum)
				local := (a * exponent + b * prime) % modulus
				smooth_sum[index] = normalize(smooth_sum[index] + local * smooth_sum[child])
				power *= prime
				exponent++
			}
		}
	}
	mut answer := smooth_sum[1]
	value = 1
	for value <= root {
		child := value_index(n / value, n, root, size)
		large_prime_sum := normalize(a * normalize(g_zero[child] - 1) + b * normalize(g_one[child] - 1))
		answer = normalize(answer + small_value(value, smallest, a, b) * large_prime_sum)
		value++
	}
	return answer
}

@[export: 'zhouge_summatory_multiplicative_function']
pub fn zhouge_summatory_multiplicative_function(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 3 { return -1 }
	unsafe {
		n := input[0]
		a := input[1]
		b := input[2]
		if n < 1 || n > max_n || a < 0 || a >= modulus || b < 0 || b >= modulus { return -1 }
		return solve(n, a, b)
	}
}
