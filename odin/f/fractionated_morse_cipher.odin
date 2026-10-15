package fractionated_morse_cipher

import "core:c"

Morse_Code: [26]u8 = {1,8,10,4,0,2,6,0,0,7,5,4,3,2,7,6,13,2,0,1,1,1,3,9,11,12}
Morse_Length: [26]int = {2,4,4,3,1,4,3,4,2,4,3,4,2,2,3,4,4,3,3,1,3,4,3,4,4,4}
Morse_Symbols: [3]u8 = {'.','-','x'}

make_keyed_alphabet :: proc(input: [^]i64, key_start, key_length: int) -> [26]u8 {
	keyed: [26]u8
	seen: [26]bool
	count := 0
	for index := 0; index < key_length; index += 1 {
		value := input[key_start + index]
		if value >= 'a' && value <= 'z' do value -= 32
		letter := int(value - 'A')
		if !seen[letter] { seen[letter] = true; keyed[count] = u8(value); count += 1 }
	}
	for letter := 0; letter < 26; letter += 1 {
		if !seen[letter] { keyed[count] = u8('A' + letter); count += 1 }
	}
	return keyed
}

morse_letter :: proc(morse: [^]u8, start, length: int) -> int {
	if length < 1 || length > 4 do return -1
	code := 0
	for offset := 0; offset < length; offset += 1 {
		bit := 0
		if morse[start + offset] == '-' do bit = 1
		code = code * 2 + bit
	}
	for letter := 0; letter < 26; letter += 1 {
		if Morse_Length[letter] == length && int(Morse_Code[letter]) == code do return letter
	}
	return -1
}

@(export)
fractionated_morse_cipher :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 3 || length > 323 do return -1
	mode := input[0]
	text_value := input[1]
	key_value := input[2]
	if (mode != 0 && mode != 1) || text_value < 0 || text_value > 256 || key_value < 0 || key_value > 64 do return -1
	text_length := int(text_value)
	key_length := int(key_value)
	if int(length) != 3 + text_length + key_length do return -1
	key_start := 3 + text_length
	for index := 0; index < key_length; index += 1 {
		value := input[key_start + index]
		if !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) do return -1
	}
	for index := 0; index < text_length; index += 1 {
		value := input[3 + index]
		if mode == 0 {
			if value != ' ' && !((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z')) do return -1
		} else if value < 'A' || value > 'Z' do return -1
	}
	keyed := make_keyed_alphabet(input, key_start, key_length)
	result: [800]u8
	result_length := 0
	if mode == 0 {
		morse: [1300]u8
		morse_length := 0
		for index := 0; index < text_length; index += 1 {
			if index != 0 { morse[morse_length] = 'x'; morse_length += 1 }
			value := input[3 + index]
			if value == ' ' do continue
			if value >= 'a' && value <= 'z' do value -= 32
			letter := int(value - 'A')
			for bit := 0; bit < Morse_Length[letter]; bit += 1 {
				mask := 1 << (Morse_Length[letter] - bit - 1)
				if (int(Morse_Code[letter]) & mask) != 0 do morse[morse_length] = '-'
				else do morse[morse_length] = '.'
				morse_length += 1
			}
		}
		padding := 3 - morse_length % 3
		for _ := 0; _ < padding; _ += 1 { morse[morse_length] = 'x'; morse_length += 1 }
		for start := 0; start < morse_length; start += 3 {
			trigram := 0
			for offset := 0; offset < 3; offset += 1 {
				digit := 2
				if morse[start + offset] == '.' do digit = 0
				if morse[start + offset] == '-' do digit = 1
				trigram = trigram * 3 + digit
			}
			if trigram < 26 { result[result_length] = keyed[trigram]; result_length += 1 }
		}
	} else {
		morse: [1300]u8
		morse_length := 0
		for index := 0; index < text_length; index += 1 {
			trigram := 0
			for trigram < 26 && keyed[trigram] != u8(input[3 + index]) { trigram += 1 }
			if trigram == 26 do return -1
			morse[morse_length] = Morse_Symbols[trigram / 9]
			morse[morse_length + 1] = Morse_Symbols[(trigram / 3) % 3]
			morse[morse_length + 2] = Morse_Symbols[trigram % 3]
			morse_length += 3
		}
		segment_start := 0
		for index := 0; index <= morse_length; index += 1 {
			if index != morse_length && morse[index] != 'x' do continue
			segment_length := index - segment_start
			if segment_length == 0 { result[result_length] = ' '; result_length += 1 }
			else {
				letter := morse_letter(&morse[0], segment_start, segment_length)
				if letter < 0 do return -1
				result[result_length] = u8('A' + letter); result_length += 1
			}
			segment_start = index + 1
		}
		first := 0
		for first < result_length && result[first] == ' ' { first += 1 }
		for result_length > first && result[result_length - 1] == ' ' { result_length -= 1 }
		if first > 0 {
			for index := first; index < result_length; index += 1 { result[index - first] = result[index] }
			result_length -= first
		}
	}
	if output_capacity < c.size_t(result_length) || (result_length != 0 && output == nil) do return -2
	for index := 0; index < result_length; index += 1 { output[index] = result[index] }
	return i64(result_length)
}
