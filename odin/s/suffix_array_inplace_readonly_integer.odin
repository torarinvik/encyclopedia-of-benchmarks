package suffix_array_inplace_readonly_integer

import "core:c"

MAX_TEXT_LENGTH :: 32
MAX_INPUT_LENGTH :: 34
PACKED_FIELD_WORDS :: 4
PACKED_LIST_WORDS :: 2

Packed_Fields :: struct { word: [PACKED_FIELD_WORDS]u64 }
Input_View :: struct {
	raw: [^]i64,
	packed: [^]u64,
	raw_length: int,
	raw_offset: int,
}

field_get :: proc "contextless" (fields: ^Packed_Fields, index: int) -> int {
	word_index := index / 9
	shift := (index % 9) * 7
	value := int((fields.word[word_index] >> u64(shift)) & 127)
	if value == 127 do return -1
	return value
}

field_set :: proc "contextless" (fields: ^Packed_Fields, index: int, value: int) {
	word_index := index / 9
	shift := (index % 9) * 7
	mask := u64(127) << u64(shift)
	encoded := u64(127)
	if value >= 0 do encoded = u64(value)
	fields.word[word_index] = (fields.word[word_index] & ~mask) | (encoded << u64(shift))
}

list_get :: proc "contextless" (list: [^]u64, index: int) -> int {
	word_index := index / 10
	shift := (index % 10) * 6
	return int((list[word_index] >> u64(shift)) & 63)
}

list_set :: proc "contextless" (list: [^]u64, index, value: int) {
	word_index := index / 10
	shift := (index % 10) * 6
	mask := u64(63) << u64(shift)
	list[word_index] = (list[word_index] & ~mask) | (u64(value) << u64(shift))
}

bit_is_set :: proc "contextless" (bits: u64, index: int) -> bool {
	return ((bits >> u64(index)) & 1) != 0
}

bit_count :: proc "contextless" (bits: u64) -> int {
	remaining := bits
	count := 0
	for remaining != 0 {
		remaining &= remaining - 1
		count += 1
	}
	return count
}

bits_below :: proc "contextless" (bits: u64, index: int) -> int {
	mask := u64(0)
	if index > 0 do mask = (u64(1) << u64(index)) - 1
	return bit_count(bits & mask)
}

symbol_at :: proc "contextless" (input: Input_View, index: int) -> int {
	if input.raw != nil {
		if index == input.raw_length do return 0
		return int(input.raw[index + input.raw_offset]) + 1
	}
	return list_get(input.packed, index)
}

sa_get :: proc "contextless" (output: [^]u8, index: int) -> i64 {
	bits: u64 = 0
	offset := index * 8
	for byte := 0; byte < 8; byte += 1 {
		bits |= u64(output[offset + byte]) << u64(byte * 8)
	}
	if (bits >> 63) != 0 do return -1
	return i64(bits)
}

sa_set :: proc "contextless" (output: [^]u8, index: int, value: i64) {
	bits := u64(value)
	if value < 0 do bits = ~u64(0)
	offset := index * 8
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8((bits >> u64(byte * 8)) & 255)
	}
}

build_buckets :: proc "contextless" (input: Input_View, length, upper: int,
			types: u64, heads, tails, s_starts: ^Packed_Fields) {
	counts: Packed_Fields = {}
	l_counts: Packed_Fields = {}
	prefix := 0
	for index := 0; index < length; index += 1 {
		symbol := symbol_at(input, index)
		field_set(&counts, symbol, field_get(&counts, symbol) + 1)
		if !bit_is_set(types, index) do field_set(&l_counts, symbol, field_get(&l_counts, symbol) + 1)
	}
	for symbol := 0; symbol <= upper; symbol += 1 {
		count := field_get(&counts, symbol)
		field_set(heads, symbol, prefix)
		field_set(tails, symbol, prefix + count - 1)
		field_set(s_starts, symbol, prefix + field_get(&l_counts, symbol))
		prefix += count
	}
}

same_lms_substring :: proc "contextless" (input: Input_View, length: int,
		types, lms: u64, left, right: int) -> bool {
	if left == right do return true
	for offset := 0; offset < length; offset += 1 {
		a := left + offset
		b := right + offset
		if a >= length || b >= length || symbol_at(input, a) != symbol_at(input, b) ||
			bit_is_set(types, a) != bit_is_set(types, b) do return false
		if offset > 0 && (bit_is_set(lms, a) || bit_is_set(lms, b)) {
			return bit_is_set(lms, a) && bit_is_set(lms, b)
		}
	}
	return false
}

induce :: proc "contextless" (input: Input_View, length, upper: int,
		types, lms: u64, seeds: [^]u64, seed_count: int,
		use_lms_mask: bool, output: [^]u8) {
	var heads, tails, l_cursor, s_cursor: Packed_Fields
	var s_starts: Packed_Fields
	build_buckets(input, length, upper, types, &heads, &tails, &s_starts)
	for index := 0; index < length; index += 1 { sa_set(output, index, -1) }
	for symbol := 0; symbol <= upper; symbol += 1 {
		field_set(&s_cursor, symbol, field_get(&s_starts, symbol))
	}
	if use_lms_mask {
		for position := 0; position < length; position += 1 {
			if !bit_is_set(lms, position) do continue
			symbol := symbol_at(input, position)
			slot := field_get(&s_cursor, symbol)
			sa_set(output, slot, i64(position))
			field_set(&s_cursor, symbol, slot + 1)
		}
	} else {
		for item := 0; item < seed_count; item += 1 {
			position := list_get(seeds, item)
			symbol := symbol_at(input, position)
			slot := field_get(&s_cursor, symbol)
			sa_set(output, slot, i64(position))
			field_set(&s_cursor, symbol, slot + 1)
		}
	}
	for symbol := 0; symbol <= upper; symbol += 1 {
		field_set(&l_cursor, symbol, field_get(&heads, symbol))
		field_set(&s_cursor, symbol, field_get(&tails, symbol) + 1)
	}
	for slot := 0; slot < length; slot += 1 {
		position := sa_get(output, slot)
		if position <= 0 do continue
		previous := int(position) - 1
		if bit_is_set(types, previous) do continue
		symbol := symbol_at(input, previous)
		target := field_get(&l_cursor, symbol)
		sa_set(output, target, i64(previous))
		field_set(&l_cursor, symbol, target + 1)
	}
	for slot := length - 1; slot >= 0; slot -= 1 {
		position := sa_get(output, slot)
		if position <= 0 do continue
		previous := int(position) - 1
		if !bit_is_set(types, previous) do continue
		symbol := symbol_at(input, previous)
		target := field_get(&s_cursor, symbol) - 1
		sa_set(output, target, i64(previous))
		field_set(&s_cursor, symbol, target)
	}
}

sais_readonly :: proc "contextless" (input: Input_View, length, upper: int,
		output: [^]u8) {
	if length == 0 do return
	if length == 1 { sa_set(output, 0, 0); return }
	if length == 2 {
		if symbol_at(input, 0) >= symbol_at(input, 1) {
			sa_set(output, 0, 1); sa_set(output, 1, 0)
		} else { sa_set(output, 0, 0); sa_set(output, 1, 1) }
		return
	}
	types := u64(1) << u64(length - 1)
	for index := length - 2; index >= 0; index -= 1 {
		current := symbol_at(input, index)
		next := symbol_at(input, index + 1)
		if current < next || (current == next && bit_is_set(types, index + 1)) {
			types |= u64(1) << u64(index)
		}
	}
	var lms: u64 = 0
	var lms_positions: [PACKED_LIST_WORDS]u64
	lms_count := 0
	for index := 1; index < length; index += 1 {
		if !bit_is_set(types, index - 1) && bit_is_set(types, index) {
			lms |= u64(1) << u64(index)
			list_set(&lms_positions[0], lms_count, index)
			lms_count += 1
		}
	}
	induce(input, length, upper, types, lms, nil, 0, true, output)
	var reduced: [PACKED_LIST_WORDS]u64
	name, sorted_count, previous_lms := 0, 0, -1
	for slot := 0; slot < length; slot += 1 {
		candidate := sa_get(output, slot)
		if candidate < 0 || !bit_is_set(lms, int(candidate)) do continue
		position := int(candidate)
		if previous_lms >= 0 && !same_lms_substring(input, length, types, lms, previous_lms, position) {
			name += 1
		}
		list_set(&reduced[0], bits_below(lms, position), name)
		previous_lms = position
		sorted_count += 1
	}
	if sorted_count != lms_count do return
	if name + 1 == lms_count {
		for ordinal := 0; ordinal < lms_count; ordinal += 1 {
			sa_set(output, list_get(&reduced[0], ordinal), i64(ordinal))
		}
	} else {
		reduced_input := Input_View{packed = &reduced[0]}
		sais_readonly(reduced_input, lms_count, name, output)
	}
	var ordered_lms: [PACKED_LIST_WORDS]u64
	for item := 0; item < lms_count; item += 1 {
		ordinal := int(sa_get(output, item))
		list_set(&ordered_lms[0], item, list_get(&lms_positions[0], ordinal))
	}
	induce(input, length, upper, types, lms, &ordered_lms[0], lms_count, false, output)
}

@(export)
suffix_array_inplace_readonly_integer :: proc "c" (values: [^]i64,
		length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := int(count_value)
	if length != c.size_t(count + 1) do return -1
	for index := 0; index < count; index += 1 {
		if values[index + 1] < 0 || values[index + 1] >= i64(count) do return -1
	}
	workspace_bytes := c.size_t(count + 1) * 8
	output_bytes := c.size_t(count) * 8
	if output == nil || capacity < workspace_bytes do return -2
	input := Input_View{raw = values, raw_length = count, raw_offset = 1}
	sais_readonly(input, count + 1, count, output)
	for index := 0; index < count; index += 1 {
		position := sa_get(output, index + 1)
		sa_set(output, index, position)
	}
	return i64(output_bytes)
}
