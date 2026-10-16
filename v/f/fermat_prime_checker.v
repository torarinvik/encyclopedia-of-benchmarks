module fermat_prime_checker

fn dotnet_sample(mut seed [56]i32, mut next int, mut next_p int) i32 {
	next++
	if next >= 56 { next = 1 }
	next_p++
	if next_p >= 56 { next_p = 1 }
	mut value := seed[next] - seed[next_p]
	if value == 2147483647 { value-- }
	if value < 0 { value += 2147483647 }
	seed[next] = value
	return value
}

fn mod_pow(base_input i64, exponent_input i64, modulus i64) i64 {
	mut base := base_input
	mut exponent := exponent_input
	mut result := i64(1)
	for exponent > 0 {
		if (exponent & 1) != 0 { result = result * base % modulus }
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@[export: 'fermat_prime_checker']
pub fn fermat_prime_checker(number i64, times_to_check i64) i64 {
	if number < 2 || number > 1000000 || times_to_check < 2 || times_to_check > 64 { return -1 }
	mut seed := [56]i32{}
	mut mj := i32(161803398)
	mut mk := i32(1)
	seed[55] = mj
	for i in 1 .. 55 {
		index := (21 * i) % 55
		seed[index] = mk
		mk = mj - mk
		if mk < 0 { mk += 2147483647 }
		mj = seed[index]
	}
	for _ in 0 .. 4 {
		for i in 1 .. 56 {
			seed[i] -= seed[1 + (i + 30) % 55]
			if seed[i] < 0 { seed[i] += 2147483647 }
		}
	}
	mut next := 0
	mut next_p := 21
	for _ in 1 .. int(times_to_check) {
		sample := dotnet_sample(mut seed, mut next, mut next_p)
		base := i64(f64(sample) / 2147483647.0 * f64(number - 1)) + 1
		if mod_pow(base, number - 1, number) != 1 { return 0 }
	}
	return 1
}
