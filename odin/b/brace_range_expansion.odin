package brace_range_expansion

import "core:c"

Endpoint :: struct {
	valid: bool,
	value: int,
	letter: bool,
	width: int,
	upper: bool,
}

Plan :: struct {
	open: int,
	close: int,
	start: int,
	step: int,
	letter: bool,
	pad: int,
	count: int,
}

endpoint :: proc(p: [^]i64, offset, first, last: int) -> Endpoint {
	n := last - first
	if n == 1 && ((p[offset+first] >= 65 && p[offset+first] <= 90) ||
		(p[offset+first] >= 97 && p[offset+first] <= 122)) {
		return Endpoint{true, int(p[offset+first]), true, 1, p[offset+first] <= 90}
	}
	if n < 1 || n > 4 do return {}
	value := 0
	for i := first; i < last; i += 1 {
		byte := p[offset+i]
		if byte < 48 || byte > 57 do return {}
		value = value*10 + int(byte-48)
	}
	return Endpoint{true, value, false, n, false}
}

parse_step :: proc(p: [^]i64, offset, first, last: int) -> int {
	at := first
	sign := 1
	if at < last && (p[offset+at] == 43 || p[offset+at] == 45) {
		if p[offset+at] == 45 do sign = -1
		at += 1
	}
	if last-at < 1 do return 0
	value := 0
	for i := at; i < last; i += 1 {
		byte := p[offset+i]
		if byte < 48 || byte > 57 do return 0
		if value < 10000 {
			value = value*10 + int(byte-48)
			if value > 10000 do value = 10000
		}
	}
	if value == 0 do return 0
	return sign*value
}

make_plan :: proc(p: [^]i64, offset, n: int, plan: ^Plan) -> bool {
	if n < 1 || n > 64 do return false
	open, close := -1, -1
	for i := 0; i < n; i += 1 {
		byte := p[offset+i]
		if byte < 32 || byte > 126 do return false
		if byte == 123 { if open >= 0 do return false; open = i }
		if byte == 125 { if close >= 0 do return false; close = i }
	}
	if open < 0 || close <= open || open+n-close-1 > 32 do return false
	sep1, sep2 := -1, -1
	for i := open+1; i+1 < close; {
		if p[offset+i] == 46 && p[offset+i+1] == 46 {
			if sep1 < 0 { sep1 = i } else if sep2 < 0 { sep2 = i } else { return false }
			i += 2
		} else { i += 1 }
	}
	if sep1 < 0 do return false
	a := endpoint(p, offset, open+1, sep1)
	end_at := close
	if sep2 >= 0 do end_at = sep2
	b := endpoint(p, offset, sep1+2, end_at)
	if !a.valid || !b.valid || a.letter != b.letter ||
		(a.letter && a.upper != b.upper) do return false
	step := 0
	if sep2 < 0 { step = 1; if a.value > b.value do step = -1 }
	else { step = parse_step(p, offset, sep2+2, close) }
	if step == 0 || (a.value < b.value && step < 0) ||
		(a.value > b.value && step > 0) do return false
	count := 1
	if a.value < b.value do count = (b.value-a.value)/step + 1
	if a.value > b.value do count = (a.value-b.value)/(-step) + 1
	if count > 16 do return false
	pad := 0
	if !a.letter && (p[offset+open+1] == 48 || p[offset+sep1+2] == 48) {
		pad = a.width
		if b.width > pad do pad = b.width
	}
	plan.open = open
	plan.close = close
	plan.start = a.value
	plan.step = step
	plan.letter = a.letter
	plan.pad = pad
	plan.count = count
	return true
}

@(export)
brace_range_expansion :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || length > 65 do return -1
	declared := input[0]
	if declared < 1 || declared > 64 || length != c.size_t(declared+1) do return -1
	n := int(declared)
	plan: Plan
	if !make_plan(input, 1, n, &plan) do return -1
	staged: [591]u8
	out, value := 0, plan.start
	suffix_start := plan.close+1
	for item := 0; item < plan.count; item += 1 {
		if item != 0 { staged[out] = 0; out += 1 }
		for i := 0; i < plan.open; i += 1 { staged[out] = u8(input[1+i]); out += 1 }
		if plan.letter { staged[out] = u8(value); out += 1 }
		else {
			digits: [4]int
			used, remaining := 0, value
			for {
				digits[used] = remaining % 10
				used += 1
				remaining /= 10
				if remaining == 0 do break
			}
			for used < plan.pad { staged[out] = 48; out += 1 }
			for used > 0 { used -= 1; staged[out] = u8(48+digits[used]); out += 1 }
		}
		for i := suffix_start; i < n; i += 1 { staged[out] = u8(input[1+i]); out += 1 }
		value += plan.step
	}
	if output == nil || capacity < c.size_t(out) do return -2
	for i := 0; i < out; i += 1 do output[i] = staged[i]
	return i64(out)
}
