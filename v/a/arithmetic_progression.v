module arithmetic_progression

// Sum an inclusive arithmetic progression from packed [from, to, step].
@[export: 'arithmetic_progression']
pub fn arithmetic_progression(values &i64, length usize) i64 {
	if length != 3 { return -1 }
	from := unsafe { values[0] }
	to := unsafe { values[1] }
	step := unsafe { values[2] }
	if from < -1000000 || from > 1000000 || to < -1000000 || to > 1000000 { return -1 }
	if step < -1000000 || step > 1000000 || step == 0 { return -1 }
	if (from < to && step < 0) || (from > to && step > 0) { return -1 }
	count := (to - from) / step
	last := from + count * step
	return ((count + 1) * (from + last)) / 2
}
