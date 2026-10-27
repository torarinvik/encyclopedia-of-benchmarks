package suffix_array_dc3

import "core:c"

MAX_TEXT_LENGTH :: 16
MAX_INPUT_LENGTH :: 18

symbol_at :: proc "contextless" (symbols: [^]i64, length, position: int) -> i64 {
	if position < length do return symbols[position]
	return 0
}

sample_rank :: proc "contextless" (ranks: [^]i64, length, position: int) -> i64 {
	if position < length do return ranks[position]
	return -1
}

triple_compare :: proc "contextless" (symbols: [^]i64, length, left, right: int) -> int {
	for offset in 0..<3 {
		a := symbol_at(symbols, length, left+offset)
		b := symbol_at(symbols, length, right+offset)
		if a != b { if a < b do return -1 else do return 1 }
	}
	return 0
}

suffix_compare :: proc "contextless" (symbols: [^]i64, length, left_start, right_start: int) -> int {
	left, right := left_start, right_start
	for left < length && right < length {
		if symbols[left] != symbols[right] { if symbols[left] < symbols[right] do return -1 else do return 1 }
		left += 1
		right += 1
	}
	if left == length && right == length do return 0
	if left == length do return -1
	return 1
}

zero_pair_compare :: proc "contextless" (symbols, ranks: [^]i64, length, left, right: int) -> int {
	a := symbol_at(symbols, length, left)
	b := symbol_at(symbols, length, right)
	if a != b { if a < b do return -1 else do return 1 }
	a = sample_rank(ranks, length, left+1)
	b = sample_rank(ranks, length, right+1)
	if a != b { if a < b do return -1 else do return 1 }
	return 0
}

merge_compare :: proc "contextless" (symbols, ranks: [^]i64, length, zero, sample: int) -> int {
	a := symbol_at(symbols, length, zero)
	b := symbol_at(symbols, length, sample)
	if a != b { if a < b do return -1 else do return 1 }
	if sample % 3 == 1 {
		a = sample_rank(ranks, length, zero+1)
		b = sample_rank(ranks, length, sample+1)
		if a != b { if a < b do return -1 else do return 1 }
	} else {
		a = symbol_at(symbols, length, zero+1)
		b = symbol_at(symbols, length, sample+1)
		if a != b { if a < b do return -1 else do return 1 }
		a = sample_rank(ranks, length, zero+2)
		b = sample_rank(ranks, length, sample+2)
		if a != b { if a < b do return -1 else do return 1 }
	}
	return 0
}

dc3 :: proc "contextless" (symbols: [^]i64, length: int, suffixes: [^]int) {
	if length == 0 do return
	if length <= 3 {
		for i := 0; i < length; i += 1 { suffixes[i] = i }
		for i := 1; i < length; i += 1 {
			key := suffixes[i]
			position := i
			for position > 0 && suffix_compare(symbols, length, key, suffixes[position-1]) < 0 {
				suffixes[position] = suffixes[position-1]
				position -= 1
			}
			suffixes[position] = key
		}
		return
	}

	sample_positions: [MAX_TEXT_LENGTH]int
	sample_count := 0
	for i := 1; i < length; i += 1 {
		if i % 3 != 0 { sample_positions[sample_count] = i; sample_count += 1 }
	}
	for i := 1; i < sample_count; i += 1 {
		key := sample_positions[i]
		position := i
		for position > 0 && triple_compare(symbols, length, key, sample_positions[position-1]) < 0 {
			sample_positions[position] = sample_positions[position-1]
			position -= 1
		}
		sample_positions[position] = key
	}

	triple_ranks: [MAX_TEXT_LENGTH]i64
	next_rank: i64 = 0
	for i := 0; i < sample_count; i += 1 {
		if i == 0 || triple_compare(symbols, length, sample_positions[i-1], sample_positions[i]) != 0 { next_rank += 1 }
		triple_ranks[sample_positions[i]] = next_rank
	}
	group_one_count := 0
	for i := 1; i < length; i += 3 { group_one_count += 1 }
	reduced: [MAX_TEXT_LENGTH]i64
	reduced_length := 0
	for i := 1; i < length; i += 3 { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1 }
	reduced[reduced_length] = 0
	reduced_length += 1
	for i := 2; i < length; i += 3 { reduced[reduced_length] = triple_ranks[i]; reduced_length += 1 }
	reduced_order: [MAX_TEXT_LENGTH]int
	dc3(raw_data(reduced[:]), reduced_length, raw_data(reduced_order[:]))

	sample_order: [MAX_TEXT_LENGTH]int
	ranks: [MAX_TEXT_LENGTH]i64
	for i := 0; i < length; i += 1 { ranks[i] = -1 }
	sample_order_count := 0
	for i := 0; i < reduced_length; i += 1 {
		reduced_position := reduced_order[i]
		if reduced_position == group_one_count do continue
		source_position := 2 + 3*(reduced_position-group_one_count-1)
		if reduced_position < group_one_count { source_position = 1 + 3*reduced_position }
		sample_order[sample_order_count] = source_position
		ranks[source_position] = i64(sample_order_count)
		sample_order_count += 1
	}

	zero_positions: [MAX_TEXT_LENGTH]int
	zero_count := 0
	for i := 0; i < length; i += 3 { zero_positions[zero_count] = i; zero_count += 1 }
	for i := 1; i < zero_count; i += 1 {
		key := zero_positions[i]
		position := i
		for position > 0 && zero_pair_compare(symbols, raw_data(ranks[:]), length, key, zero_positions[position-1]) < 0 {
			zero_positions[position] = zero_positions[position-1]
			position -= 1
		}
		zero_positions[position] = key
	}

	zi, si, oi := 0, 0, 0
	for zi < zero_count && si < sample_order_count {
		zero, sample := zero_positions[zi], sample_order[si]
		if merge_compare(symbols, raw_data(ranks[:]), length, zero, sample) < 0 {
			suffixes[oi] = zero_positions[zi]; zi += 1
		} else {
			suffixes[oi] = sample_order[si]; si += 1
		}
		oi += 1
	}
	for zi < zero_count { suffixes[oi] = zero_positions[zi]; zi += 1; oi += 1 }
	for si < sample_order_count { suffixes[oi] = sample_order[si]; si += 1; oi += 1 }
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: int) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(byte*8)) }
}

@(export)
suffix_array_dc3 :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := int(count_value)
	if length != c.size_t(count+1) do return -1
	for i := 0; i < count; i += 1 { if values[i+1] < 0 || values[i+1] > 255 do return -1 }
	output_bytes := count * 8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	if count == 0 do return 0
	symbols: [MAX_TEXT_LENGTH]i64
	for i := 0; i < count; i += 1 { symbols[i] = values[i+1] + 1 }
	suffixes: [MAX_TEXT_LENGTH]int
	dc3(raw_data(symbols[:]), count, raw_data(suffixes[:]))
	for i := 0; i < count; i += 1 { store_i64_le(output, i*8, suffixes[i]) }
	return i64(output_bytes)
}
