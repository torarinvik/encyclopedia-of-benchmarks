module suffix_array_inplace_readonly_integer

const max_text_length = 32
const max_input_length = 34

type PackedFields = [4]u64
type PackedList = [2]u64

struct InputView {
	raw        []i64
	packed     []u64
	raw_length int
	raw_offset int
	is_packed  bool
}

fn field_get(fields PackedFields, index int) int {
	value := int((fields[index / 9] >> u64((index % 9) * 7)) & 127)
	if value == 127 { return -1 }
	return value
}

fn field_set(mut fields PackedFields, index int, value int) {
	word_index := index / 9
	shift := (index % 9) * 7
	mask := u64(127) << u64(shift)
	encoded := if value < 0 { u64(127) } else { u64(value) }
	fields[word_index] = (fields[word_index] & ~mask) | (encoded << u64(shift))
}

fn list_get(list []u64, index int) int {
	int((list[index / 10] >> u64((index % 10) * 6)) & 63)
}

fn list_set(mut list PackedList, index int, value int) {
	word_index := index / 10
	shift := (index % 10) * 6
	mask := u64(63) << u64(shift)
	list[word_index] = (list[word_index] & ~mask) | (u64(value) << u64(shift))
}

fn bit_is_set(bits u64, index int) bool { ((bits >> u64(index)) & 1) != 0 }

fn bit_count(bits u64) int {
	mut remaining := bits
	mut count := 0
	for remaining != 0 {
		remaining &= remaining - 1
		count++
	}
	return count
}

fn bits_below(bits u64, index int) int {
	mask := if index == 0 { u64(0) } else { (u64(1) << u64(index)) - 1 }
	return bit_count(bits & mask)
}

fn symbol_at(input InputView, index int) int {
	if !input.is_packed {
		if index == input.raw_length { return 0 }
		return int(input.raw[index + input.raw_offset]) + 1
	}
	word_index := index / 10
	shift := (index % 10) * 6
	return int((input.packed[word_index] >> u64(shift)) & 63)
}

fn sa_get(output []u8, index int) i64 {
	mut bits := u64(0)
	offset := index * 8
	for byte in 0 .. 8 { bits |= u64(output[offset + byte]) << u64(byte * 8) }
	if (bits >> 63) != 0 { return -1 }
	return i64(bits)
}

fn sa_set(mut output []u8, index int, value i64) {
	bits := if value < 0 { u64(0xffffffffffffffff) } else { u64(value) }
	offset := index * 8
	for byte in 0 .. 8 { output[offset + byte] = u8((bits >> u64(byte * 8)) & 255) }
}

fn build_buckets(input InputView, length int, upper int, types u64,
	mut heads PackedFields, mut tails PackedFields, mut s_starts PackedFields) {
	mut counts := PackedFields{}
	mut l_counts := PackedFields{}
	mut prefix := 0
	for index in 0 .. length {
		symbol := symbol_at(input, index)
		field_set(mut counts, symbol, field_get(counts, symbol) + 1)
		if !bit_is_set(types, index) { field_set(mut l_counts, symbol, field_get(l_counts, symbol) + 1) }
	}
	for symbol in 0 .. upper + 1 {
		count := field_get(counts, symbol)
		field_set(mut heads, symbol, prefix)
		field_set(mut tails, symbol, prefix + count - 1)
		field_set(mut s_starts, symbol, prefix + field_get(l_counts, symbol))
		prefix += count
	}
}

fn same_lms_substring(input InputView, length int, types u64, lms u64, left int, right int) bool {
	if left == right { return true }
	for offset in 0 .. length {
		a := left + offset
		b := right + offset
		if a >= length || b >= length || symbol_at(input, a) != symbol_at(input, b) ||
			bit_is_set(types, a) != bit_is_set(types, b) { return false }
		if offset > 0 && (bit_is_set(lms, a) || bit_is_set(lms, b)) {
			return bit_is_set(lms, a) && bit_is_set(lms, b)
		}
	}
	return false
}

fn induce(input InputView, length int, upper int, types u64, lms u64,
	seeds []u64, seed_count int, use_lms_mask bool, mut output []u8) {
	mut heads := PackedFields{}
	mut tails := PackedFields{}
	mut s_starts := PackedFields{}
	mut l_cursor := PackedFields{}
	mut s_cursor := PackedFields{}
	build_buckets(input, length, upper, types, mut heads, mut tails, mut s_starts)
	for index in 0 .. length { sa_set(mut output, index, -1) }
	for symbol in 0 .. upper + 1 { field_set(mut s_cursor, symbol, field_get(s_starts, symbol)) }
	if use_lms_mask {
		for position in 0 .. length {
			if !bit_is_set(lms, position) { continue }
			symbol := symbol_at(input, position)
			slot := field_get(s_cursor, symbol)
			sa_set(mut output, slot, i64(position))
			field_set(mut s_cursor, symbol, slot + 1)
		}
	} else {
		for item in 0 .. seed_count {
			position := list_get(seeds, item)
			symbol := symbol_at(input, position)
			slot := field_get(s_cursor, symbol)
			sa_set(mut output, slot, i64(position))
			field_set(mut s_cursor, symbol, slot + 1)
		}
	}
	for symbol in 0 .. upper + 1 {
		field_set(mut l_cursor, symbol, field_get(heads, symbol))
		field_set(mut s_cursor, symbol, field_get(tails, symbol) + 1)
	}
	for slot in 0 .. length {
		position := sa_get(output, slot)
		if position <= 0 { continue }
		previous := int(position) - 1
		if bit_is_set(types, previous) { continue }
		symbol := symbol_at(input, previous)
		target := field_get(l_cursor, symbol)
		sa_set(mut output, target, i64(previous))
		field_set(mut l_cursor, symbol, target + 1)
	}
	for slot := length - 1; slot >= 0; slot-- {
		position := sa_get(output, slot)
		if position <= 0 { continue }
		previous := int(position) - 1
		if !bit_is_set(types, previous) { continue }
		symbol := symbol_at(input, previous)
		target := field_get(s_cursor, symbol) - 1
		sa_set(mut output, target, i64(previous))
		field_set(mut s_cursor, symbol, target)
	}
}

fn sais_readonly(input InputView, length int, upper int, mut output []u8) {
	if length == 0 { return }
	if length == 1 { sa_set(mut output, 0, 0); return }
	if length == 2 {
		if symbol_at(input, 0) >= symbol_at(input, 1) {
			sa_set(mut output, 0, 1); sa_set(mut output, 1, 0)
		} else { sa_set(mut output, 0, 0); sa_set(mut output, 1, 1) }
		return
	}
	mut types := u64(1) << u64(length - 1)
	for index := length - 2; index >= 0; index-- {
		current := symbol_at(input, index)
		next := symbol_at(input, index + 1)
		if current < next || (current == next && bit_is_set(types, index + 1)) {
			types |= u64(1) << u64(index)
		}
	}
	mut lms := u64(0)
	mut lms_positions := PackedList{}
	mut lms_count := 0
	for index in 1 .. length {
		if !bit_is_set(types, index - 1) && bit_is_set(types, index) {
			lms |= u64(1) << u64(index)
			list_set(mut lms_positions, lms_count, index)
			lms_count++
		}
	}
	empty_seeds := PackedList{}
	induce(input, length, upper, types, lms, empty_seeds[:], 0, true, mut output)
	mut reduced := PackedList{}
	mut name := 0
	mut sorted_count := 0
	mut previous_lms := -1
	for slot in 0 .. length {
		candidate := sa_get(output, slot)
		if candidate < 0 || !bit_is_set(lms, int(candidate)) { continue }
		position := int(candidate)
		if previous_lms >= 0 && !same_lms_substring(input, length, types, lms, previous_lms, position) {
			name++
		}
		list_set(mut reduced, bits_below(lms, position), name)
		previous_lms = position
		sorted_count++
	}
	if sorted_count != lms_count { return }
	if name + 1 == lms_count {
		for ordinal in 0 .. lms_count { sa_set(mut output, list_get(reduced[:], ordinal), i64(ordinal)) }
	} else {
		reduced_input := InputView{packed: reduced[:], is_packed: true}
		sais_readonly(reduced_input, lms_count, name, mut output)
	}
	mut ordered_lms := PackedList{}
	for item in 0 .. lms_count {
		ordinal := int(sa_get(output, item))
		list_set(mut ordered_lms, item, list_get(lms_positions[:], ordinal))
	}
	induce(input, length, upper, types, lms, ordered_lms[:], lms_count, false, mut output)
}

@[export: 'suffix_array_inplace_readonly_integer']
pub fn suffix_array_inplace_readonly_integer(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 1 || length > max_input_length { return -1 }
		count_value := values[0]
		if count_value < 0 || count_value > max_text_length { return -1 }
		count := int(count_value)
		if length != usize(count + 1) { return -1 }
		for index in 0 .. count {
			if values[index + 1] < 0 || values[index + 1] >= i64(count) { return -1 }
		}
		workspace_bytes := usize(count + 1) * 8
		output_bytes := usize(count) * 8
		if output == nil || capacity < workspace_bytes { return -2 }
		input_values := values[0..length]
		mut output_view := output[0..workspace_bytes]
		input := InputView{raw: input_values, raw_length: count, raw_offset: 1}
		sais_readonly(input, count + 1, count, mut output_view)
		for index in 0 .. count {
			position := sa_get(output_view, index + 1)
			sa_set(mut output_view, index, position)
		}
		return i64(output_bytes)
	}
}
