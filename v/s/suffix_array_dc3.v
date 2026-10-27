const max_text_length = 16
const max_input_length = 18

fn symbol_at(symbols &i64, length int, position int) i64 {
	unsafe { if position < length { return symbols[position] } }
	return 0
}

fn sample_rank(ranks &i64, length int, position int) i64 {
	unsafe { if position < length { return ranks[position] } }
	return -1
}

fn triple_compare(symbols &i64, length int, left int, right int) int {
	for offset := 0; offset < 3; offset++ {
		a := symbol_at(symbols, length, left + offset)
		b := symbol_at(symbols, length, right + offset)
		if a != b { return if a < b { -1 } else { 1 } }
	}
	return 0
}

fn suffix_compare(symbols &i64, length int, left_start int, right_start int) int {
	mut left := left_start
	mut right := right_start
	unsafe {
		for left < length && right < length {
			if symbols[left] != symbols[right] { return if symbols[left] < symbols[right] { -1 } else { 1 } }
			left++
			right++
		}
	}
	if left == length && right == length { return 0 }
	return if left == length { -1 } else { 1 }
}

fn zero_pair_compare(symbols &i64, ranks &i64, length int, left int, right int) int {
	a := symbol_at(symbols, length, left)
	b := symbol_at(symbols, length, right)
	if a != b { return if a < b { -1 } else { 1 } }
	a = sample_rank(ranks, length, left + 1)
	b = sample_rank(ranks, length, right + 1)
	if a != b { return if a < b { -1 } else { 1 } }
	return 0
}

fn merge_compare(symbols &i64, ranks &i64, length int, zero int, sample int) int {
	a := symbol_at(symbols, length, zero)
	b := symbol_at(symbols, length, sample)
	if a != b { return if a < b { -1 } else { 1 } }
	if sample % 3 == 1 {
		a = sample_rank(ranks, length, zero + 1)
		b = sample_rank(ranks, length, sample + 1)
		if a != b { return if a < b { -1 } else { 1 } }
	} else {
		a = symbol_at(symbols, length, zero + 1)
		b = symbol_at(symbols, length, sample + 1)
		if a != b { return if a < b { -1 } else { 1 } }
		a = sample_rank(ranks, length, zero + 2)
		b = sample_rank(ranks, length, sample + 2)
		if a != b { return if a < b { -1 } else { 1 } }
	}
	return 0
}

fn dc3(symbols &i64, length int, mut suffixes &int) {
	unsafe {
		if length == 0 { return }
		if length <= 3 {
			for i := 0; i < length; i++ { suffixes[i] = i }
			for i := 1; i < length; i++ {
				key := suffixes[i]
				mut position := i
				for position > 0 && suffix_compare(symbols, length, key, suffixes[position - 1]) < 0 {
					suffixes[position] = suffixes[position - 1]
					position--
				}
				suffixes[position] = key
			}
			return
		}

		mut sample_positions := [16]int{}
		mut sample_count := 0
		for i := 1; i < length; i++ {
			if i % 3 != 0 { sample_positions[sample_count] = i; sample_count++ }
		}
		for i := 1; i < sample_count; i++ {
			key := sample_positions[i]
			mut position := i
			for position > 0 && triple_compare(symbols, length, key, sample_positions[position - 1]) < 0 {
				sample_positions[position] = sample_positions[position - 1]
				position--
			}
			sample_positions[position] = key
		}

		mut triple_ranks := [16]i64{}
		mut next_rank := i64(0)
		for i := 0; i < sample_count; i++ {
			if i == 0 || triple_compare(symbols, length, sample_positions[i - 1], sample_positions[i]) != 0 { next_rank++ }
			triple_ranks[sample_positions[i]] = next_rank
		}
		mut group_one_count := 0
		mut i := 1
		for i < length { group_one_count++; i += 3 }
		mut reduced := [16]i64{}
		mut reduced_length := 0
		i = 1
		for i < length { reduced[reduced_length] = triple_ranks[i]; reduced_length++; i += 3 }
		reduced[reduced_length] = 0
		reduced_length++
		i = 2
		for i < length { reduced[reduced_length] = triple_ranks[i]; reduced_length++; i += 3 }
		mut reduced_order := [16]int{}
		dc3(&reduced[0], reduced_length, mut &reduced_order[0])

		mut sample_order := [16]int{}
		mut ranks := [16]i64{}
		for i = 0; i < length; i++ { ranks[i] = -1 }
		mut sample_order_count := 0
		for i = 0; i < reduced_length; i++ {
			reduced_position := reduced_order[i]
			if reduced_position == group_one_count { continue }
			source_position := if reduced_position < group_one_count { 1 + 3 * reduced_position } else { 2 + 3 * (reduced_position - group_one_count - 1) }
			sample_order[sample_order_count] = source_position
			ranks[source_position] = i64(sample_order_count)
			sample_order_count++
		}

		mut zero_positions := [16]int{}
		mut zero_count := 0
		i = 0
		for i < length { zero_positions[zero_count] = i; zero_count++; i += 3 }
		for i := 1; i < zero_count; i++ {
			key := zero_positions[i]
			mut position := i
			for position > 0 && zero_pair_compare(symbols, &ranks[0], length, key, zero_positions[position - 1]) < 0 {
				zero_positions[position] = zero_positions[position - 1]
				position--
			}
			zero_positions[position] = key
		}

		mut zi := 0
		mut si := 0
		mut oi := 0
		for zi < zero_count && si < sample_order_count {
			zero := zero_positions[zi]
			sample := sample_order[si]
			if merge_compare(symbols, &ranks[0], length, zero, sample) < 0 {
				suffixes[oi] = zero_positions[zi]; zi++
			} else {
				suffixes[oi] = sample_order[si]; si++
			}
			oi++
		}
		for zi < zero_count { suffixes[oi] = zero_positions[zi]; zi++; oi++ }
		for si < sample_order_count { suffixes[oi] = sample_order[si]; si++; oi++ }
	}
}

fn put_i64_le(mut output &u8, offset int, value int) {
	unsafe {
		bits := u64(value)
		for byte := 0; byte < 8; byte++ { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
	}
}

@[export: 'suffix_array_dc3']
pub fn suffix_array_dc3(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_input_length { return -1 }
		count_value := values[0]
		if count_value < 0 || count_value > max_text_length { return -1 }
		count := int(count_value)
		if length != usize(count + 1) { return -1 }
		for i := 0; i < count; i++ { if values[i + 1] < 0 || values[i + 1] > 255 { return -1 } }
		output_bytes := count * 8
		if output == nil || capacity < usize(output_bytes) { return -2 }
		if count == 0 { return 0 }
		mut symbols := [16]i64{}
		for i := 0; i < count; i++ { symbols[i] = values[i + 1] + 1 }
		mut suffixes := [16]int{}
		dc3(&symbols[0], count, mut &suffixes[0])
		for i := 0; i < count; i++ { put_i64_le(mut output, i * 8, suffixes[i]) }
		return i64(output_bytes)
	}
}
