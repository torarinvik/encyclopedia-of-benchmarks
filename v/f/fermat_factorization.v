module fermat_factorization

fn integer_sqrt_i64(value i64, upper i64) i64 {
	mut low := i64(0)
	mut high := upper + 1
	for low + 1 < high {
		middle := low + (high - low) / 2
		if middle * middle <= value { low = middle } else { high = middle }
	}
	return low
}

@[export: 'fermat_factorization']
pub fn fermat_factorization(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		number, max_steps := input[0], input[1]
		if number < 3 || number > 1_000_000_000_000 || number % 2 == 0 || max_steps < 0 || max_steps > 4096 { return -1 }
		mut candidate := integer_sqrt_i64(number, 1_000_000)
		if candidate * candidate < number { candidate++ }
		mut step := i64(0)
		for step < max_steps {
			difference := candidate * candidate - number
			root := integer_sqrt_i64(difference, candidate)
			if root * root == difference {
				factor := candidate - root
				if factor > 1 && factor < number { return factor }
			}
			candidate++
			step++
		}
		return 0
	}
}
