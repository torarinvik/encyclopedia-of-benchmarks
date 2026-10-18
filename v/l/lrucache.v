@[export: 'lrucache']
pub fn lrucache(input &i64, input_length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 2 || input_length > 99 { return -1 }
		capacity_value := input[0]
		operation_count_value := input[1]
		if capacity_value < 2 || capacity_value > 16 || operation_count_value < 0 || operation_count_value > 32 { return -1 }
		cache_capacity := int(capacity_value)
		operation_count := int(operation_count_value)
		if int(input_length) != 2 + 3 * operation_count { return -1 }

		mut keys := [16]i64{}
		mut cached_values := [16]i64{}
		mut seen_put_keys := [32]i64{}
		mut operation_records := [96]i64{}
		mut used := 0
		mut seen_count := 0

		for operation in 0 .. operation_count {
			opcode := input[2 + 3 * operation]
			key := input[3 + 3 * operation]
			value := input[4 + 3 * operation]
			if opcode != 0 && opcode != 1 { return -1 }
			if key < 0 || key > 1000000 { return -1 }
			mut returned_value := i64(-1)
			mut evicted_key := i64(-1)
			mut position := 0
			for position < used && keys[position] != key { position++ }

			if opcode == 0 {
				if value < 0 || value > 1000000 { return -1 }
				for prior in 0 .. seen_count { if seen_put_keys[prior] == key { return -1 } }
				seen_put_keys[seen_count] = key
				seen_count++
				if used == cache_capacity {
					evicted_key = keys[0]
					for index in 1 .. used {
						keys[index - 1] = keys[index]
						cached_values[index - 1] = cached_values[index]
					}
					used--
				}
				keys[used] = key
				cached_values[used] = value
				used++
			} else {
				if value != 0 || position == used { return -1 }
				returned_value = cached_values[position]
				for index in position + 1 .. used {
					keys[index - 1] = keys[index]
					cached_values[index - 1] = cached_values[index]
				}
				keys[used - 1] = key
				cached_values[used - 1] = returned_value
			}
			operation_records[3 * operation] = opcode
			operation_records[3 * operation + 1] = returned_value
			operation_records[3 * operation + 2] = evicted_key
		}

		mut fields := [130]i64{}
		mut word_count := 0
		fields[word_count] = operation_count_value
		word_count++
		for index in 0 .. 3 * operation_count {
			fields[word_count] = operation_records[index]
			word_count++
		}
		fields[word_count] = i64(used)
		word_count++
		for index in 0 .. used {
			reverse_index := used - 1 - index
			fields[word_count] = keys[reverse_index]
			fields[word_count + 1] = cached_values[reverse_index]
			word_count += 2
		}

		output_bytes := word_count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		for index in 0 .. word_count {
			bits := u64(fields[index])
			for byte_index in 0 .. 8 {
				output[index * 8 + byte_index] = u8((bits >> (byte_index * 8)) & u64(0xff))
			}
		}
		return i64(output_bytes)
	}
}
