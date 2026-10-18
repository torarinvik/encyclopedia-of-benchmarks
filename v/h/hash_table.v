module hash_table

const table_capacity = 17
const max_insert_count = 8
const max_query_count = 8
const max_key = i64(1000)
const max_parseable_length = 19

fn store_i64_le(output &u8, offset int, value i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte++ {
		unsafe { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'hash_table']
pub fn hash_table(values &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > usize(max_parseable_length) { return -1 }
		raw_insert_count := values[0]
		if raw_insert_count < 0 || raw_insert_count > max_insert_count { return -1 }
		insert_count := int(raw_insert_count)
		query_count_index := 1 + insert_count
		if usize(query_count_index) >= length { return -1 }
		raw_query_count := values[query_count_index]
		if raw_query_count < 1 || raw_query_count > max_query_count { return -1 }
		query_count := int(raw_query_count)
		query_start := query_count_index + 1
		total_keys := insert_count + query_count
		if length != usize(query_start + query_count) { return -1 }

		for index := 0; index < total_keys; index++ {
			position := if index < insert_count { 1 + index } else { query_start + index - insert_count }
			key := values[position]
			if key < 1 || key > max_key { return -1 }
			for prior := 0; prior < index; prior++ {
				prior_position := if prior < insert_count { 1 + prior } else { query_start + prior - insert_count }
				other := values[prior_position]
				same_group := (index < insert_count) == (prior < insert_count)
				if key == other {
					if same_group { return -1 }
				} else if key % table_capacity == other % table_capacity || key % 3000 == other % 3000 {
					return -1
				}
			}
		}

		mut table := [table_capacity]i64{init: 0}
		for index := 0; index < insert_count; index++ {
			key := values[1 + index]
			table[int(key % table_capacity)] = key
		}

		output_bytes := 8 * query_count
		if output == nil || output_capacity < usize(output_bytes) { return -2 }
		for index := 0; index < query_count; index++ {
			query := values[query_start + index]
			found := i64(0)
			if table[int(query % table_capacity)] == query { found = 1 }
			store_i64_le(output, 8 * index, found)
		}
		return i64(output_bytes)
	}
}
