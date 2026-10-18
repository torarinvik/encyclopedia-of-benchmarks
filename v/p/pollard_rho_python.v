const max_num = i64(1_000_000)

fn gcd_nonnegative(mut left i64, mut right i64) i64 {
	for right != 0 {
		remainder := left % right
		left = right
		right = remainder
	}
	return left
}

fn advance(value i64, step i64, modulus i64) i64 {
	return (value * value + step) % modulus
}

@[export: 'pollard_rho_python']
pub fn pollard_rho_python(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 5 { return -1 }
	unsafe {
		num := input[0]
		mut seed := input[1]
		mut step := input[2]
		attempts := input[3]
		step_limit := input[4]
		if num < 2 || num > max_num || seed < 0 || seed >= num || step < 0 || step > 1000 || attempts < 1 || attempts > 8 || step_limit < 1 || step_limit > 64 { return -1 }
		if num > 2 && num % 2 == 0 { return 2 }

		for _ in 0 .. int(attempts) {
			mut tortoise := seed
			mut hare := seed
			for _ in 0 .. int(step_limit) {
				tortoise = advance(tortoise, step, num)
				hare = advance(advance(hare, step, num), step, num)
				difference := if hare >= tortoise { hare - tortoise } else { tortoise - hare }
				divisor := gcd_nonnegative(difference, num)
				if divisor == 1 { continue }
				if divisor < num { return divisor }
				break
			}
			seed = hare
			step += 1
		}
		return 0
	}
}
