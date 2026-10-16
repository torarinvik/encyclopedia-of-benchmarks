package fermat_prime_checker

 dotnet_sample :: proc(seed: ^[56]i32, next: ^i32, next_p: ^i32) -> i32 {
	(*next) += 1
	if (*next) >= 56 do (*next) = 1
	(*next_p) += 1
	if (*next_p) >= 56 do (*next_p) = 1
	value := seed[(*next)] - seed[(*next_p)]
	if value == 2_147_483_647 do value -= 1
	if value < 0 do value += 2_147_483_647
	seed[(*next)] = value
	return value
}

mod_pow :: proc(base_input, exponent_input, modulus: i64) -> i64 {
	base, exponent := base_input, exponent_input
	result: i64 = 1
	for exponent > 0 {
		if (exponent & 1) != 0 do result = result * base % modulus
		base = base * base % modulus
		exponent >>= 1
	}
	return result
}

@(export, link_name="fermat_prime_checker")
fermat_prime_checker :: proc "c" (number, times_to_check: i64) -> i64 {
	if number < 2 || number > 1_000_000 || times_to_check < 2 || times_to_check > 64 do return -1
	seed: [56]i32
	mj, mk: i32 = 161_803_398, 1
	seed[55] = mj
	for i: i32 = 1; i < 55; i += 1 {
		index := (21 * i) % 55
		seed[index] = mk
		mk = mj - mk
		if mk < 0 do mk += 2_147_483_647
		mj = seed[index]
	}
	for pass: i32 = 0; pass < 4; pass += 1 {
		for i: i32 = 1; i < 56; i += 1 {
			seed[i] -= seed[1 + (i + 30) % 55]
			if seed[i] < 0 do seed[i] += 2_147_483_647
		}
	}
	next, next_p: i32 = 0, 21
	for iteration: i64 = 1; iteration < times_to_check; iteration += 1 {
		sample := dotnet_sample(&seed, &next, &next_p)
		base := i64(f64(sample) / 2_147_483_647.0 * f64(number - 1)) + 1
		if mod_pow(base, number - 1, number) != 1 do return 0
	}
	return 1
}

main :: proc() {}
