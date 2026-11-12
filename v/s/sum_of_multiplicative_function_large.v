module sum_of_multiplicative_function_large

const modulus = i64(469_762_049)
const max_n = i64(100_000_000)

fn floor_sqrt(value i64) i64 {
	mut low := i64(1)
	mut high := i64(10_000)
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

fn triangular_mod(value i64) i64 {
	mut left := value
	mut right := value + 1
	if left & 1 == 0 { left /= 2 } else { right /= 2 }
	return left % modulus * (right % modulus) % modulus
}

fn value_index(value i64, n i64, root i64, size int) int {
	if value <= root { return size - int(value) }
	return int(n / value)
}

fn solve(n i64, a i64, b i64) i64 {
	root := floor_sqrt(n)
	mut high_count := int(n / root)
	for high_count > 1 && n / i64(high_count - 1) == root { high_count-- }
	size := high_count + int(root)
	mut quotients := []i64{len: size, init: 0}
	mut prime_count := []i64{len: size, init: 0}
	mut prime_sum := []i64{len: size, init: 0}
	mut composite := []bool{len: int(root) + 1, init: false}
	mut primes := []i64{}
	mut index := 1
	for index < high_count {
		quotients[index] = n / i64(index)
		index++
	}
	mut value := i64(1)
	for value <= root {
		quotients[size - int(value)] = value
		value++
	}
	value = 2
	for value <= root {
		if composite[int(value)] {
			value++
			continue
		}
		primes << value
		if value <= root / value {
			mut multiple := value * value
			for multiple <= root {
				composite[int(multiple)] = true
				multiple += value
			}
		}
		value++
	}

	index = 1
	for index < size {
		prime_count[index] = quotients[index] - 1
		prime_sum[index] = normalize(triangular_mod(quotients[index]) - 1)
		index++
	}
	mut preceding_count := i64(0)
	mut preceding_sum := i64(0)
	for prime in primes {
		square := prime * prime
		index = 1
		for index < size && quotients[index] >= square {
			quotient_index := value_index(quotients[index] / prime, n, root, size)
			prime_count[index] -= prime_count[quotient_index] - preceding_count
			sum_delta := normalize(prime_sum[quotient_index] - preceding_sum)
			prime_sum[index] = normalize(prime_sum[index] - (prime % modulus) * sum_delta)
			index++
		}
		preceding_count++
		preceding_sum = normalize(preceding_sum + prime)
	}
	mut values := []i64{len: size, init: 0}
	mut next_values := []i64{len: size, init: 0}
	index = 1
	for index < size {
		values[index] = (a * (prime_count[index] % modulus) + b * prime_sum[index]) % modulus
		next_values[index] = values[index]
		index++
	}

	mut position := primes.len
	for position > 0 {
		position--
		prime := primes[position]
		mut power := prime
		mut exponent := i64(1)
		prime_prefix := values[value_index(prime, n, root, size)]
		for n / prime >= power {
			local := (a * exponent + b * prime) % modulus
			next_local := (a * (exponent + 1) + b * prime) % modulus
			next_power := power * prime
			index = 1
			for index < size && next_power <= quotients[index] {
				quotient_index := value_index(quotients[index] / power, n, root, size)
				non_prime_sum := normalize(values[quotient_index] - prime_prefix)
				next_values[index] = normalize(next_values[index] + local * non_prime_sum + next_local)
				index++
			}
			power = next_power
			exponent++
		}
		mut copied := value_index(prime * prime, n, root, size) + 1
		if copied > size { copied = size }
		index = 0
		for index < copied {
			values[index] = next_values[index]
			index++
		}
	}
	return normalize(values[value_index(n, n, root, size)] + 1)
}

@[export: 'sum_of_multiplicative_function_large']
pub fn sum_of_multiplicative_function_large(input &i64, length usize) i64 {
	if input == nil || length != 3 { return -1 }
	unsafe {
		n := input[0]
		a := input[1]
		b := input[2]
		if n < 1 || n > max_n || a < 0 || a >= modulus || b < 0 || b >= modulus { return -1 }
		return solve(n, a, b)
	}
}
