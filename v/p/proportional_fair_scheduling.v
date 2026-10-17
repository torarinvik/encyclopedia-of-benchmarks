module proportional_fair_scheduling

fn store_i64_le(mut output &u8, position int, value i64) {
	mut bits := u64(value)
	for byte in 0 .. 8 {
		unsafe { output[position + byte] = u8(bits & 0xff) }
		bits >>= 8
	}
}

@[export: 'proportional_fair_scheduling']
pub fn proportional_fair_scheduling(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { values == nil } || length < 2 || length > 131 { return -1 }
	unsafe {
		if values[0] < 0 || values[0] > 64 || values[1] < 1 || values[1] > 1000000 { return -1 }
		process_count, total_resources := int(values[0]), values[1]
		if length != usize(2 + 2 * process_count) { return -1 }
		mut name_ids := [64]i64{}
		mut weights := [64]i64{}
		mut total_weight := i64(0)
		for process in 0 .. process_count {
			name_id, weight := values[2 + 2 * process], values[3 + 2 * process]
			if name_id < -2147483648 || name_id > 2147483647 || weight < 1 || weight > 1000000 { return -1 }
			name_ids[process], weights[process] = name_id, weight
			total_weight += weight
		}
		if process_count == 0 { return 0 }
		required := process_count * 16
		if unsafe { output == nil } || output_capacity < usize(required) { return -2 }
		for process in 0 .. process_count {
			quotient := f64(weights[process]) / f64(total_weight)
			share := quotient * f64(total_resources)
			allocation := i32(share)
			store_i64_le(mut output, process * 16, name_ids[process])
			store_i64_le(mut output, process * 16 + 8, i64(allocation))
		}
		return i64(required)
	}
}
