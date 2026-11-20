module baum_sweet_sequence

fn baum_sweet_term(number i64) i64 {
	if number == 0 { return 0 }
	mut mask := i64(1)
	for mask <= number / 2 { mask *= 2 }
	mut odd_zero_run := false
	for mask > 0 {
		if (number & mask) != 0 {
			if odd_zero_run { return 0 }
			odd_zero_run = false
		} else {
			odd_zero_run = !odd_zero_run
		}
		mask /= 2
	}
	return if odd_zero_run { 0 } else { 1 }
}

@[export: 'baum_sweet_sequence']
pub fn baum_sweet_sequence(input &i64, length usize) i64 {
	if unsafe { input == nil } || length != 1 { return -1 }
	count := unsafe { input[0] }
	if count < 0 || count > 63 { return -1 }
	mut packed := i64(0)
	mut bit := i64(1)
	for index in 0 .. int(count) {
		if baum_sweet_term(i64(index)) != 0 { packed += bit }
		if index + 1 < int(count) { bit *= 2 }
	}
	return packed
}
