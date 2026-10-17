module least_recently_used

@[export: 'least_recently_used']
pub fn least_recently_used(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 66 { return -1 }
	capacity_value := unsafe { input[0] }
	reference_count_value := unsafe { input[1] }
	if capacity_value < 1 || capacity_value > 16 || reference_count_value < 0 || reference_count_value > 64 { return -1 }
	cache_capacity := int(capacity_value)
	references := int(reference_count_value)
	if length != usize(2 + references) { return -1 }
	for i in 0 .. references {
		key := unsafe { input[2 + i] }
		if key < -2147483648 || key > 2147483647 { return -1 }
	}

	mut keys := [16]i64{}
	mut count := 0
	for i in 0 .. references {
		key := unsafe { input[2 + i] }
		mut found := count
		for j in 0 .. count { if keys[j] == key { found = j; break } }
		if found < count {
			mut j := found
			for j + 1 < count { keys[j] = keys[j + 1]; j++ }
			count--
		} else if count == cache_capacity { count-- }
		mut j := count
		for j > 0 { keys[j] = keys[j - 1]; j-- }
		keys[0] = key
		count++
	}

	elements := count + 1
	required := elements * 8
	if output == nil || output_capacity < usize(required) { return -2 }
	unsafe {
		mut bits := u64(count)
		for byte in 0 .. 8 {
			output[byte] = u8(bits & 255)
			bits >>= 8
		}
		for i in 0 .. count {
			bits = u64(keys[i])
			for byte in 0 .. 8 {
				output[(i + 1) * 8 + byte] = u8(bits & 255)
				bits >>= 8
			}
		}
	}
	return i64(elements)
}
