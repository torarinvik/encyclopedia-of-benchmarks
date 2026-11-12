package sum_of_multiplicative_function_large

import "core:c"

Modulus :: i64(469_762_049)
Max_N :: i64(100_000_000)

floor_sqrt :: proc "contextless" (value: i64) -> i64 {
	low, high := i64(1), i64(10_000)
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

triangular_mod :: proc "contextless" (value: i64) -> i64 {
	left, right := value, value + 1
	if (left & 1) == 0 { left /= 2 } else { right /= 2 }
	return (left % Modulus) * (right % Modulus) % Modulus
}

value_index :: proc "contextless" (value, n, root: i64, size: int) -> int {
	if value <= root { return size - int(value) }
	return int(n / value)
}

@(export)
sum_of_multiplicative_function_large :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length != 3 do return -1
	n, a, b := input[0], input[1], input[2]
	if n < 1 || n > Max_N || a < 0 || a >= Modulus || b < 0 || b >= Modulus do return -1

	root := floor_sqrt(n)
	high_count := int(n / root)
	for high_count > 1 && n / i64(high_count - 1) == root { high_count -= 1 }
	size := high_count + int(root)
	quotients := make([]i64, size); defer delete(quotients)
	prime_count := make([]i64, size); defer delete(prime_count)
	prime_sum := make([]i64, size); defer delete(prime_sum)
	composite := make([]bool, int(root)+1); defer delete(composite)
	values := make([]i64, size); defer delete(values)
	next_values := make([]i64, size); defer delete(next_values)
	primes: [10_001]i64 = {}
	prime_total := 0
	for i := 1; i < high_count; i += 1 { quotients[i] = n / i64(i) }
	for value := i64(1); value <= root; value += 1 { quotients[size-int(value)] = value }
	for value := i64(2); value <= root; value += 1 {
		if composite[int(value)] { continue }
		primes[prime_total] = value
		prime_total += 1
		if value <= root/value {
			for multiple := value*value; multiple <= root; multiple += value { composite[int(multiple)] = true }
		}
	}

	for i := 1; i < size; i += 1 {
		prime_count[i] = quotients[i] - 1
		prime_sum[i] = normalize(triangular_mod(quotients[i]) - 1)
	}
	preceding_count, preceding_sum := i64(0), i64(0)
	for p_index := 0; p_index < prime_total; p_index += 1 {
		prime := primes[p_index]
		square := prime * prime
		for i := 1; i < size && quotients[i] >= square; i += 1 {
			quotient_index := value_index(quotients[i]/prime, n, root, size)
			prime_count[i] -= prime_count[quotient_index] - preceding_count
			sum_delta := normalize(prime_sum[quotient_index] - preceding_sum)
			prime_sum[i] = normalize(prime_sum[i] - (prime % Modulus) * sum_delta)
		}
		preceding_count += 1
		preceding_sum = normalize(preceding_sum + prime)
	}
	prime_f := make([]i64, size); defer delete(prime_f)
	for i := 1; i < size; i += 1 {
		prime_f[i] = (a*(prime_count[i]%Modulus) + b*prime_sum[i]) % Modulus
		values[i] = prime_f[i]
		next_values[i] = prime_f[i]
	}

	position := prime_total
	for position > 0 {
		position -= 1
		prime := primes[position]
		power, exponent := prime, i64(1)
		prime_prefix := prime_f[value_index(prime, n, root, size)]
		for n/prime >= power {
			local := (a*exponent + b*prime) % Modulus
			next_local := (a*(exponent+1) + b*prime) % Modulus
			next_power := power * prime
			for i := 1; i < size && next_power <= quotients[i]; i += 1 {
				quotient_index := value_index(quotients[i]/power, n, root, size)
				non_prime_sum := normalize(values[quotient_index] - prime_prefix)
				next_values[i] = normalize(next_values[i] + local*non_prime_sum + next_local)
			}
			power = next_power
			exponent += 1
		}
		copied := value_index(prime*prime, n, root, size) + 1
		if copied > size { copied = size }
		for i := 0; i < copied; i += 1 { values[i] = next_values[i] }
	}
	return normalize(values[value_index(n, n, root, size)] + 1)
}
