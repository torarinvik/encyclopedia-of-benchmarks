module integer_sequence_codes

const max_n = 32
const max_input = 35
const max_output = 4096
const max_result = 512

fn emit_bit(mut out []u8, mut used int, value bool) {
	out[used] = if value { u8(`1`) } else { u8(`0`) }
	used++
}
fn emit_byte(mut out []u8, mut used int, value u8) { out[used] = value; used++ }
fn emit_number(mut out []u8, mut used int, value u64, width int) {
	mut shift := width - 1
	for shift >= 0 {
		emit_bit(mut out, mut used, ((value >> shift) & 1) != 0)
		shift--
	}
}
fn emit_unary(mut out []u8, mut used int, value u64) {
	for _ in 0 .. int(value) { emit_bit(mut out, mut used, true) }
	emit_bit(mut out, mut used, false)
}
fn floor_log2(value u64) int {
	mut remaining := value
	mut width := -1
	for remaining != 0 {
		width++
		remaining >>= 1
	}
	return width
}
fn emit_minimal(mut out []u8, mut used int, value u64, universe u64) {
	if universe == 1 { return }
	low_width := floor_log2(universe)
	short_count := (u64(1) << (low_width + 1)) - universe
	if value < short_count { emit_number(mut out, mut used, value, low_width) }
	else { emit_number(mut out, mut used, value + short_count, low_width + 1) }
}
fn emit_gamma(mut out []u8, mut used int, value u64) {
	shifted := value + 1
	width := floor_log2(shifted)
	emit_unary(mut out, mut used, u64(width))
	emit_number(mut out, mut used, shifted - (u64(1) << width), width)
}
fn emit_delta(mut out []u8, mut used int, value u64) {
	shifted := value + 1
	width := floor_log2(shifted)
	emit_gamma(mut out, mut used, u64(width))
	emit_number(mut out, mut used, shifted - (u64(1) << width), width)
}
fn emit_interpolative(mut out []u8, mut used int, values []i64, left int, right int, low i64, high i64) {
	if left >= right { return }
	middle := left + (right - left - 1) / 2
	value := values[middle]
	lower := low + i64(middle - left)
	upper := high - i64(right - middle - 1)
	emit_minimal(mut out, mut used, u64(value - lower), u64(upper - lower))
	emit_interpolative(mut out, mut used, values, left, middle, low, value)
	emit_interpolative(mut out, mut used, values, middle + 1, right, value + 1, high)
}
fn s9_slots(selector int) int {
	if selector == 0 { return 28 }
	if selector == 1 { return 14 }
	if selector == 2 { return 9 }
	if selector == 3 { return 7 }
	if selector == 4 { return 5 }
	if selector == 5 { return 4 }
	if selector == 6 { return 3 }
	if selector == 7 { return 2 }
	return 1
}
fn s9_width(selector int) int {
	if selector == 0 { return 1 }
	if selector == 1 { return 2 }
	if selector == 2 { return 3 }
	if selector == 3 { return 4 }
	if selector == 4 { return 5 }
	if selector == 5 { return 7 }
	if selector == 6 { return 9 }
	if selector == 7 { return 14 }
	return 28
}
fn emit_simple9(mut out []u8, mut used int, values []i64) {
	mut position := 0
	for position < values.len {
		mut selector := 0
		mut take := 0
		mut width := 0
		for s in 0 .. 9 {
			slots := s9_slots(s)
			field_width := s9_width(s)
			count := if slots < values.len-position { slots } else { values.len-position }
			mut fits := true
			for j in 0 .. count { if u64(values[position+j]) >= (u64(1) << field_width) { fits = false } }
			if fits { selector=s; take=count; width=field_width; break }
		}
		mut word := u64(selector) << 28
		slots := s9_slots(selector)
		for j in 0 .. take { word |= u64(values[position+j]) << (28-width*(j+1)) }
		emit_number(mut out, mut used, word, 32)
		position += take
	}
}

@[export: 'integer_sequence_codes']
pub fn integer_sequence_codes(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if input == nil || length < 4 || length > max_input { return -1 }
	unsafe {
		mode := input[0]
		n0 := input[1]
		parameter := input[2]
		if mode < 0 || mode > 9 || n0 < 1 || n0 > max_n || length != usize(n0 + 3) { return -1 }
		n := int(n0)
		values := input[3..3+n]
		if mode == 0 {
			if parameter != 0 { return -1 }
			for value in values { if value < 0 || value > 31 { return -1 } }
		} else if mode == 1 {
			if parameter < 2 || parameter > 1000000 { return -1 }
			for value in values { if value < 0 || value >= parameter { return -1 } }
		} else if mode == 2 || mode == 3 {
			if parameter != 0 { return -1 }
			for value in values { if value < 0 || value > 1000000 { return -1 } }
		} else if mode == 4 {
			if parameter < 1 || parameter > 128 { return -1 }
			for value in values { if value < 0 || value > 127 { return -1 } }
		} else if mode == 7 {
			if parameter != 0 { return -1 }
			for value in values { if value < 0 || value > 1000000 { return -1 } }
		} else if mode == 8 {
			if parameter != 0 { return -1 }
			for value in values { if value < 0 || value >= (i64(1) << 28) { return -1 } }
		} else if mode == 9 {
			if parameter < 1 || parameter > 20 { return -1 }
			for value in values { if value < 0 || value > 1000000 { return -1 } }
		} else {
			if parameter < 2 || parameter > 4096 || n0 > parameter { return -1 }
			for i, value in values {
				if value < 0 || value >= parameter || (i > 0 && values[i - 1] >= value) { return -1 }
			}
		}
		mut staged := []u8{len: max_output, init: 0}
		mut used := 0
		if mode == 0 {
			for value in values { emit_unary(mut staged, mut used, u64(value)) }
		} else if mode == 1 {
			for value in values { emit_minimal(mut staged, mut used, u64(value), u64(parameter)) }
		} else if mode == 2 {
			for value in values { emit_gamma(mut staged, mut used, u64(value)) }
		} else if mode == 3 {
			for value in values { emit_delta(mut staged, mut used, u64(value)) }
		} else if mode == 4 {
			b := u64(parameter)
			for value in values {
				x := u64(value)
				emit_unary(mut staged, mut used, x / b)
				emit_minimal(mut staged, mut used, x % b, b)
			}
		} else if mode == 5 {
			mut width := 0
			for u64(n) * (u64(1) << (width + 1)) <= u64(parameter) { width++ }
			bucket_size := u64(1) << width
			buckets := int((u64(parameter) + bucket_size - 1) / bucket_size)
			mut counts := []u8{len: 4096, init: 0}
			for value in values { counts[int(u64(value) / bucket_size)]++ }
			for bucket in 0 .. buckets { emit_unary(mut staged, mut used, u64(counts[bucket])) }
			for value in values { emit_number(mut staged, mut used, u64(value) % bucket_size, width) }
		} else if mode == 6 {
			emit_interpolative(mut staged, mut used, values, 0, n, 0, parameter)
		} else if mode == 7 {
			for value in values {
				x := u64(value); mut highest := floor_log2(x)
				if highest < 0 { highest = 0 } else { highest = (highest / 7) * 7 }
				mut shift := highest
				for shift >= 0 { mut byte := u8((x >> shift) & 0x7f); if shift != 0 { byte |= 0x80 }; emit_byte(mut staged, mut used, byte); shift -= 7 }
			}
		} else if mode == 8 {
			emit_simple9(mut staged, mut used, values)
		} else {
			width := int(parameter); low_mask := (u64(1) << width) - 1; mut exception_count := 0
			for value in values { x := u64(value); emit_number(mut staged, mut used, x & low_mask, width); if x >= (u64(1) << width) { exception_count++ } }
			emit_number(mut staged, mut used, u64(exception_count), 6)
			mut position_width := 0
			for (1 << position_width) < n { position_width++ }
			for i, value in values { x := u64(value); if x >= (u64(1) << width) { emit_number(mut staged, mut used, u64(i), position_width); emit_number(mut staged, mut used, x, 20) } }
		}
		if output == nil { return -2 }
		if mode == 7 { if capacity < usize(used) { return -2 }; for i in 0 .. used { unsafe { output[i] = staged[i] } }; return i64(used) }
		bytes := (used + 7) / 8
		if capacity < usize(bytes) { return -2 }
		mut packed := []u8{len: max_result, init: 0}
		for i in 0 .. used { if staged[i] == u8(`1`) { packed[i/8] |= u8(1) << (7-i%8) } }
		for i in 0 .. bytes { unsafe { output[i] = packed[i] } }
		return i64(bytes)
	}
}
