module lifocache

@[export: 'lifocache']
pub fn lifocache(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 2 || length > 194 { return -1 }
	capacity_value := unsafe { input[0] }
	operation_count_value := unsafe { input[1] }
	if capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64 { return -1 }
	capacity := int(capacity_value)
	operations := int(operation_count_value)
	if length != usize(2 + 3 * operations) { return -1 }
	for i in 0 .. operations {
		op := unsafe { input[2 + 3 * i] }
		key := unsafe { input[3 + 3 * i] }
		value := unsafe { input[4 + 3 * i] }
		if op < 0 || op > 6 { return -1 }
		if op <= 2 {
			if key < -2147483648 || key > 2147483647 { return -1 }
			if op == 0 {
				if value < -2147483648 || value > 2147483647 { return -1 }
			} else if value != 0 { return -1 }
		} else if key != 0 || value != 0 { return -1 }
	}

	required := operations * 16
	if output == nil || output_capacity < usize(required) { return -2 }
	mut keys := [16]i64{}
	mut values := [16]i64{}
	mut count := 0
	mut hits := i64(0)
	mut misses := i64(0)
	for i in 0 .. operations {
		op := unsafe { input[2 + 3 * i] }
		key := unsafe { input[3 + 3 * i] }
		value := unsafe { input[4 + 3 * i] }
		mut first := i64(0)
		mut second := i64(0)
		if op == 0 {
			mut found := count
			for j in 0 .. count { if keys[j] == key { found = j; break } }
			if found < count {
				mut j := found
				for j + 1 < count { keys[j] = keys[j + 1]; values[j] = values[j + 1]; j++ }
				count--
			}
			if count == capacity { count-- }
			keys[count] = key
			values[count] = value
			count++
			first = 1
		} else if op == 1 {
			mut found := count
			for j in 0 .. count { if keys[j] == key { found = j; break } }
			if found < count { hits++; first = 1; second = values[found] } else { misses++ }
		} else if op == 2 {
			mut found := count
			for j in 0 .. count { if keys[j] == key { found = j; break } }
			if found < count {
				first = 1
				second = values[found]
				mut j := found
				for j + 1 < count { keys[j] = keys[j + 1]; values[j] = values[j + 1]; j++ }
				count--
			}
		} else if op == 3 { first = i64(count) }
		else if op == 4 { first = hits }
		else if op == 5 { first = misses }
		else { count = 0; hits = 0; misses = 0; first = 1 }
		first_bits := u64(first)
		second_bits := u64(second)
		for byte in 0 .. 8 {
			unsafe {
				output[i * 16 + byte] = u8((first_bits >> (8 * byte)) & 255)
				output[i * 16 + 8 + byte] = u8((second_bits >> (8 * byte)) & 255)
			}
		}
	}
	return i64(2 * operations)
}
