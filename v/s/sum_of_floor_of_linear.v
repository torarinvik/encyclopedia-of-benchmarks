module sum_of_floor_of_linear

fn floor_sum(n_input i64, m_input i64, a_input i64, b_input i64) i64 {
	mut n := n_input
	mut m := m_input
	mut a := a_input
	mut b := b_input
	mut answer := i64(0)
	for {
		if a >= m {
			quotient := a / m
			mut left := n
			mut right := n - 1
			if left % 2 == 0 { left /= 2 } else { right /= 2 }
			answer += left * right * quotient
			a %= m
		}
		if b >= m {
			answer += n * (b / m)
			b %= m
		}
		numerator := a * n + b
		height := numerator / m
		if height == 0 { return answer }
		b = numerator % m
		n = height
		previous_m := m
		m = a
		a = previous_m
	}
	return answer
}

@[export: 'sum_of_floor_of_linear']
pub fn sum_of_floor_of_linear(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	n := unsafe { input[0] }
	m := unsafe { input[1] }
	a := unsafe { input[2] }
	b := unsafe { input[3] }
	if n < 1 || n > 1_000_000_000 || m < 1 || m > 1_000_000_000 { return -1 }
	if a < 0 || a >= m || b < 0 || b >= m { return -1 }
	return floor_sum(n, m, a, b)
}
