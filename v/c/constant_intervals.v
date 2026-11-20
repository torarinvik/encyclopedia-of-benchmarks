module constant_intervals

const max_n = 256

struct IntervalState {
	output &u8
mut:
	count int
	last_hi int
	last_value i32
	has_last bool
}

fn value_at(index int, step i64, offset i64, divisor i64) i32 {
	return i32((step * i64(index) + offset) / divisor)
}

fn store_i32_le(output &u8, position int, value i32) {
	bits := u32(value)
	for byte in 0 .. 4 {
		unsafe { output[position + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
}

fn append_interval(mut state IntervalState, lo int, hi int, value i32) {
	if state.has_last && state.last_hi == lo && state.last_value == value {
		store_i32_le(state.output, (state.count - 1) * 12 + 4, i32(hi))
	} else {
		position := state.count * 12
		store_i32_le(state.output, position, i32(lo))
		store_i32_le(state.output, position + 4, i32(hi))
		store_i32_le(state.output, position + 8, value)
		state.count++
	}
	state.last_hi = hi
	state.last_value = value
	state.has_last = true
}

fn visit_range(lo int, hi int, step i64, offset i64, divisor i64, mut state IntervalState) {
	first := value_at(lo, step, offset, divisor)
	last := value_at(hi - 1, step, offset, divisor)
	if first == last || hi - lo == 1 {
		append_interval(mut state, lo, hi, first)
		return
	}
	mid := lo + (hi - lo) / 2
	visit_range(lo, mid, step, offset, divisor, mut state)
	visit_range(mid, hi, step, offset, divisor, mut state)
}

@[export: 'constant_intervals']
pub fn constant_intervals(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	n_value := unsafe { input[0] }
	step := unsafe { input[1] }
	offset := unsafe { input[2] }
	divisor := unsafe { input[3] }
	if n_value < 0 || n_value > max_n || step < 0 || step > 65535
		|| offset < 0 || offset > 65535 || divisor < 1 || divisor > 65535 { return -1 }
	n := int(n_value)
	maximum_bytes := n * 12
	if output_capacity < maximum_bytes || (maximum_bytes > 0 && unsafe { output == nil }) { return -2 }
	if n == 0 { return 0 }
	mut state := IntervalState{output: output}
	visit_range(0, n, step, offset, divisor, mut state)
	return i64(state.count)
}
