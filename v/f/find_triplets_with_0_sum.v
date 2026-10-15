module find_triplets_with_0_sum

const max_items = 64
const bytes_per_triplet = 12

fn write_i32_le(output &u8, offset int, value i64) {
	bits := u32(i32(value))
	unsafe {
		for byte in 0 .. 4 { output[offset + byte] = u8((bits >> u32(byte * 8)) & 255) }
	}
}

fn enumerate(values &i64, length int, output &u8, write_output bool) int {
	mut count := 0
	mut has_last := false
	mut last_a := i64(0)
	mut last_b := i64(0)
	mut last_c := i64(0)
	unsafe {
		for i := 0; i + 2 < length; i++ {
			for j := i + 1; j + 1 < length; j++ {
				for k := j + 1; k < length; k++ {
					if values[i] + values[j] + values[k] != 0 { continue }
					if has_last && values[i] == last_a && values[j] == last_b && values[k] == last_c { continue }
					if write_output {
						offset := count * bytes_per_triplet
						write_i32_le(output, offset, values[i])
						write_i32_le(output, offset + 4, values[j])
						write_i32_le(output, offset + 8, values[k])
					}
					last_a = values[i]; last_b = values[j]; last_c = values[k]; has_last = true
					count++
				}
			}
		}
	}
	return count
}

@[export: 'find_triplets_with_0_sum']
pub fn find_triplets_with_0_sum(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if length > max_items || (length > 0 && unsafe { input == nil }) { return -1 }
	mut values := [64]i64{}
	unsafe {
		for i := usize(0); i < length; i++ {
			if input[i] < -100000 || input[i] > 100000 { return -1 }
			values[i] = input[i]
		}
	}
	for i := 1; i < int(length); i++ {
		key := values[i]
		mut j := i
		for j > 0 && values[j - 1] > key { values[j] = values[j - 1]; j-- }
		values[j] = key
	}
	count := enumerate(&values[0], int(length), output, false)
	if count == 0 { return 0 }
	needed := usize(count * bytes_per_triplet)
	if unsafe { output == nil } || output_capacity < needed { return -2 }
	return i64(enumerate(&values[0], int(length), output, true))
}
