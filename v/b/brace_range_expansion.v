struct Endpoint {
	valid bool
	value int
	letter bool
	width int
	upper bool
}

struct Plan {
	open int
	close int
	start int
	step int
	letter bool
	pad int
	count int
}

fn endpoint(p &i64, offset int, first int, last int) Endpoint {
	n := last - first
	a := unsafe { p[offset + first] }
	if n == 1 && ((a >= 65 && a <= 90) || (a >= 97 && a <= 122)) {
		return Endpoint{true, int(a), true, 1, a <= 90}
	}
	if n < 1 || n > 4 { return Endpoint{} }
	mut value := 0
	for i in first .. last {
		byte := unsafe { p[offset + i] }
		if byte < 48 || byte > 57 { return Endpoint{} }
		value = value * 10 + int(byte - 48)
	}
	return Endpoint{true, value, false, n, false}
}

fn parse_step(p &i64, offset int, first int, last int) int {
	mut at := first
	mut sign := 1
	if at < last {
		byte := unsafe { p[offset + at] }
		if byte == 43 || byte == 45 {
			if byte == 45 { sign = -1 }
			at++
		}
	}
	if last - at < 1 { return 0 }
	mut value := 0
	for i in at .. last {
		byte := unsafe { p[offset + i] }
		if byte < 48 || byte > 57 { return 0 }
		if value < 10000 {
			value = value * 10 + int(byte - 48)
			if value > 10000 { value = 10000 }
		}
	}
	if value == 0 { return 0 }
	return sign * value
}

fn make_plan(p &i64, offset int, n int) ?Plan {
	if n < 1 || n > 64 { return none }
	mut open := -1
	mut close := -1
	for i in 0 .. n {
		byte := unsafe { p[offset + i] }
		if byte < 32 || byte > 126 { return none }
		if byte == 123 {
			if open >= 0 { return none }
			open = i
		} else if byte == 125 {
			if close >= 0 { return none }
			close = i
		}
	}
	if open < 0 || close <= open || open + n - close - 1 > 32 { return none }
	mut sep1 := -1
	mut sep2 := -1
	mut i := open + 1
	for i + 1 < close {
		if unsafe { p[offset + i] == 46 && p[offset + i + 1] == 46 } {
			if sep1 < 0 { sep1 = i } else if sep2 < 0 { sep2 = i } else { return none }
			i += 2
		} else { i++ }
	}
	if sep1 < 0 { return none }
	a := endpoint(p, offset, open + 1, sep1)
	end_at := if sep2 < 0 { close } else { sep2 }
	b := endpoint(p, offset, sep1 + 2, end_at)
	if !a.valid || !b.valid || a.letter != b.letter ||
		(a.letter && a.upper != b.upper) { return none }
	mut step := if a.value <= b.value { 1 } else { -1 }
	if sep2 >= 0 {
		step = parse_step(p, offset, sep2 + 2, close)
	}
	if step == 0 || (a.value < b.value && step < 0) ||
		(a.value > b.value && step > 0) { return none }
	mut count := 1
	if a.value < b.value { count = (b.value - a.value) / step + 1 }
	if a.value > b.value { count = (a.value - b.value) / (-step) + 1 }
	if count > 16 { return none }
	mut pad := 0
	if !a.letter && (unsafe { p[offset + open + 1] == 48 } ||
		unsafe { p[offset + sep1 + 2] == 48 }) {
		pad = if a.width > b.width { a.width } else { b.width }
	}
	return Plan{open, close, a.value, step, a.letter, pad, count}
}

@[export: 'brace_range_expansion']
pub fn brace_range_expansion(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 || length > 65 { return -1 }
	declared := unsafe { input[0] }
	if declared < 1 || declared > 64 || length != usize(declared + 1) { return -1 }
	n := int(declared)
	plan := make_plan(input, 1, n) or { return -1 }
	mut staged := [591]u8{}
	mut out := 0
	mut value := plan.start
	suffix_start := plan.close + 1
	for item in 0 .. plan.count {
		if item != 0 { staged[out] = 0; out++ }
		for i in 0 .. plan.open {
			staged[out] = u8(unsafe { input[1 + i] })
			out++
		}
		if plan.letter {
			staged[out] = u8(value)
			out++
		} else {
			mut digits := [4]int{}
			mut used := 0
			mut remaining := value
			for {
				digits[used] = remaining % 10
				used++
				remaining /= 10
				if remaining == 0 { break }
			}
			for used < plan.pad { staged[out] = 48; out++ }
			for used > 0 { used--; staged[out] = u8(48 + digits[used]); out++ }
		}
		for i in suffix_start .. n {
			staged[out] = u8(unsafe { input[1 + i] })
			out++
		}
		value += plan.step
	}
	if unsafe { output == nil } || capacity < out { return -2 }
	unsafe {
		for i in 0 .. out { output[i] = staged[i] }
	}
	return i64(out)
}
