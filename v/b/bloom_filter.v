module bloom_filter

const max_trace_values = 256
const max_key = i64(1_000_000_000)

@[export: 'bloom_filter']
pub fn bloom_filter(trace &i64, length usize, output &mut u8, output_capacity usize) i64 {
	if length > max_trace_values || length % 2 != 0 { return -1 }
	mut query_count := usize(0)
	for index in 0 .. length / 2 {
		operation := unsafe { trace[index * 2] }
		key := unsafe { trace[index * 2 + 1] }
		if (operation != 1 && operation != 2) || key < 0 || key > max_key { return -1 }
		if operation == 2 { query_count++ }
	}
	if output_capacity < query_count { return -2 }

	mut bits := u64(0)
	mut written := usize(0)
	for index in 0 .. length / 2 {
		operation := unsafe { trace[index * 2] }
		key := unsafe { trace[index * 2 + 1] }
		first := u32((key * 17 + 3) % 64)
		second := u32((key * 31 + 7) % 64)
		first_mask := u64(1) << first
		second_mask := u64(1) << second
		if operation == 1 {
			bits |= first_mask | second_mask
		} else {
			present := (bits & first_mask) != 0 && (bits & second_mask) != 0
			if present {
				unsafe { output[written] = 1 }
			} else {
				unsafe { output[written] = 0 }
			}
			written++
		}
	}
	return i64(written)
}
