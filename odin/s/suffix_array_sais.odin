package suffix_array_sais

import "core:c"

MAX_TEXT_LENGTH :: 32
MAX_INPUT_LENGTH :: 34
MAX_ALPHABET :: 256

induce :: proc "contextless" (symbols: [^]i32, length, upper: int,
		is_s: [^]bool, sum_s, sum_l: [^]int,
		ordered_lms: [^]int, lms_count: int, suffixes: [^]int) {
	bucket: [MAX_ALPHABET+2]int = 0
	for i := 0; i < length; i += 1 { suffixes[i] = -1 }
	for i := 0; i <= upper+1; i += 1 { bucket[i] = sum_s[i] }
	for i := 0; i < lms_count; i += 1 {
		position := ordered_lms[i]
		symbol := int(symbols[position])
		suffixes[bucket[symbol]] = position
		bucket[symbol] += 1
	}
	for i := 0; i <= upper+1; i += 1 { bucket[i] = sum_l[i] }
	for i := 0; i < length; i += 1 {
		position := suffixes[i]
		if position > 0 && !is_s[position-1] {
			symbol := int(symbols[position-1])
			suffixes[bucket[symbol]] = position-1
			bucket[symbol] += 1
		}
	}
	for i := 0; i <= upper+1; i += 1 { bucket[i] = sum_l[i] }
	i := length
	for i > 0 {
		i -= 1
		position := suffixes[i]
		if position > 0 && is_s[position-1] {
			symbol := int(symbols[position-1])+1
			bucket[symbol] -= 1
			suffixes[bucket[symbol]] = position-1
		}
	}
}

same_lms :: proc "contextless" (symbols: [^]i32, is_s: [^]bool,
		lms_map: [^]int, length, left, right: int) -> bool {
	if left == right do return true
	for offset := 0; offset < length; offset += 1 {
		a, b := left+offset, right+offset
		if a >= length || b >= length || symbols[a] != symbols[b] || is_s[a] != is_s[b] do return false
		a_lms := offset > 0 && lms_map[a] >= 0
		b_lms := offset > 0 && lms_map[b] >= 0
		if a_lms || b_lms do return a_lms && b_lms
	}
	return false
}

sais :: proc "contextless" (symbols: [^]i32, length, upper: int, suffixes: [^]int) {
	if length == 0 do return
	if length <= 2 {
		for i := 0; i < length; i += 1 { suffixes[i] = i }
		if length == 2 && symbols[0] >= symbols[1] { suffixes[0] = 1; suffixes[1] = 0 }
		return
	}

	is_s: [MAX_TEXT_LENGTH+1]bool = false
	is_s[length-1] = true
	i := length-1
	for i > 0 {
		i -= 1
		is_s[i] = symbols[i] < symbols[i+1] || (symbols[i] == symbols[i+1] && is_s[i+1])
	}
	lms_map: [MAX_TEXT_LENGTH+2]int = -1
	lms: [MAX_TEXT_LENGTH+1]int = 0
	lms_count := 0
	for i := 1; i < length; i += 1 {
		if !is_s[i-1] && is_s[i] { lms_map[i] = lms_count; lms[lms_count] = i; lms_count += 1 }
	}
	sum_s: [MAX_ALPHABET+2]int = 0
	sum_l: [MAX_ALPHABET+2]int = 0
	for i := 0; i < length; i += 1 {
		symbol := int(symbols[i])
		if is_s[i] { sum_l[symbol+1] += 1 } else { sum_s[symbol] += 1 }
	}
	for symbol := 0; symbol <= upper; symbol += 1 {
		sum_s[symbol] += sum_l[symbol]
		sum_l[symbol+1] += sum_s[symbol]
	}
	induce(symbols, length, upper, raw_data(is_s[:]), raw_data(sum_s[:]), raw_data(sum_l[:]), raw_data(lms[:]), lms_count, suffixes)

	sorted_lms: [MAX_TEXT_LENGTH+1]int = 0
	sorted_count := 0
	for i := 0; i < length; i += 1 {
		position := suffixes[i]
		if position >= 0 && lms_map[position] >= 0 { sorted_lms[sorted_count] = position; sorted_count += 1 }
	}
	reduced: [MAX_TEXT_LENGTH+1]i32 = 0
	reduced_upper := 0
	for i := 0; i < sorted_count; i += 1 {
		if i > 0 && !same_lms(symbols, raw_data(is_s[:]), raw_data(lms_map[:]), length, sorted_lms[i-1], sorted_lms[i]) { reduced_upper += 1 }
		reduced[lms_map[sorted_lms[i]]] = i32(reduced_upper)
	}
	reduced_order: [MAX_TEXT_LENGTH+1]int = 0
	if reduced_upper+1 == sorted_count {
		for i := 0; i < sorted_count; i += 1 { reduced_order[int(reduced[i])] = i }
	} else {
		sais(raw_data(reduced[:]), sorted_count, reduced_upper, raw_data(reduced_order[:]))
	}
	ordered_lms: [MAX_TEXT_LENGTH+1]int = 0
	for i := 0; i < sorted_count; i += 1 { ordered_lms[i] = lms[reduced_order[i]] }
	induce(symbols, length, upper, raw_data(is_s[:]), raw_data(sum_s[:]), raw_data(sum_l[:]), raw_data(ordered_lms[:]), sorted_count, suffixes)
}

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) {
	bits := u64(value)
	for byte := 0; byte < 8; byte += 1 { output[offset+byte] = u8(bits >> u64(byte*8)) }
}

@(export)
suffix_array_sais :: proc "c" (values: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > MAX_INPUT_LENGTH do return -1
	count_value := values[0]
	if count_value < 0 || count_value > MAX_TEXT_LENGTH do return -1
	count := int(count_value)
	if length != c.size_t(count+1) do return -1
	for i := 0; i < count; i += 1 { if values[i+1] < 0 || values[i+1] > 255 do return -1 }
	output_bytes := count*8
	if output == nil || capacity < c.size_t(output_bytes) do return -2
	symbols: [MAX_TEXT_LENGTH+1]i32 = 0
	for i := 0; i < count; i += 1 { symbols[i] = i32(values[i+1])+1 }
	symbols[count] = 0
	suffixes: [MAX_TEXT_LENGTH+1]int = 0
	sais(raw_data(symbols[:]), count+1, 256, raw_data(suffixes[:]))
	out := 0
	for i := 0; i <= count; i += 1 {
		if suffixes[i] == count do continue
		store_i64_le(output, out*8, i64(suffixes[i]))
		out += 1
	}
	return i64(output_bytes)
}
