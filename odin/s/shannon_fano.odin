package shannon_fano

import "core:c"

MAX_TEXT_LENGTH :: 64
MAX_INPUT_LENGTH :: 66
MAX_SYMBOLS :: 10
MAX_OUTPUT_BYTES :: 111

Frame :: struct {
	start: int,
	finish: int,
	bits: u16,
	length: int,
}

@(export)
shannon_fano_generate_codes :: proc "c" (input: [^]i64, input_length: c.size_t,
			output: [^]u8, output_capacity: c.size_t) -> i64 {
	null_empty := input == nil && input_length == 0
	if input == nil && !null_empty do return -1
	var text: [MAX_TEXT_LENGTH]u8
	text_length := 0
	if !null_empty {
		if input_length < 1 || input_length > MAX_INPUT_LENGTH do return -1
		length_value := input[0]
		if length_value < 0 || length_value > MAX_TEXT_LENGTH do return -1
		text_length = int(length_value)
		if int(input_length) != 1+text_length do return -1
		for index := 0; index < text_length; index += 1 {
			code := input[1+index]
			if code < 0 || code > 127 do return -1
			text[index] = u8(code)
		}
	}

	var frequencies: [128]int
	for index := 0; index < text_length; index += 1 { frequencies[text[index]] += 1 }
	var symbols: [128]int
	symbol_count := 0
	for symbol := 0; symbol < 128; symbol += 1 {
		if frequencies[symbol] > 0 {
			symbols[symbol_count] = symbol
			symbol_count += 1
		}
	}
	if symbol_count > MAX_SYMBOLS do return -1
	for left := 0; left < symbol_count; left += 1 {
		for right := left+1; right < symbol_count; right += 1 {
			if frequencies[symbols[left]] == frequencies[symbols[right]] do return -1
		}
	}
	for index := 1; index < symbol_count; index += 1 {
		value := symbols[index]
		position := index
		for position > 0 && frequencies[symbols[position-1]] < frequencies[value] {
			symbols[position] = symbols[position-1]
			position -= 1
		}
		symbols[position] = value
	}

	var code_bits: [128]u16
	var code_lengths: [128]int
	if symbol_count == 1 {
		code_lengths[symbols[0]] = 1
	} else if symbol_count > 1 {
		var stack: [20]Frame
		stack_length := 1
		stack[0] = Frame{start = 0, finish = symbol_count-1, bits = 0, length = 0}
		for stack_length > 0 {
			stack_length -= 1
			frame := stack[stack_length]
			if frame.start == frame.finish {
				symbol := symbols[frame.start]
				code_bits[symbol] = frame.bits
				code_lengths[symbol] = frame.length
				continue
			}
			total := 0
			for index := frame.start; index <= frame.finish; index += 1 {
				total += frequencies[symbols[index]]
			}
			left_sum := 0
			best_difference := MAX_TEXT_LENGTH + 1
			split := frame.start
			for index := frame.start; index < frame.finish; index += 1 {
				left_sum += frequencies[symbols[index]]
				right_sum := total-left_sum
				difference := left_sum-right_sum
				if difference < 0 { difference = -difference }
				if difference < best_difference {
					best_difference = difference
					split = index
				}
			}
			next_length := frame.length+1
			stack[stack_length] = Frame{start = split+1, finish = frame.finish,
				bits = (frame.bits << 1) | 1, length = next_length}
			stack_length += 1
			stack[stack_length] = Frame{start = frame.start, finish = split,
				bits = frame.bits << 1, length = next_length}
			stack_length += 1
		}
	}

	var bytes: [MAX_OUTPUT_BYTES]u8
	written := 0
	bytes[written] = u8(symbol_count)
	written += 1
	for symbol := 0; symbol < 128; symbol += 1 {
		code_length := code_lengths[symbol]
		if code_length == 0 do continue
		bytes[written] = u8(symbol)
		bytes[written+1] = u8(code_length)
		written += 2
		for offset := 0; offset < code_length; offset += 1 {
			bit := (code_bits[symbol] >> u16(code_length-1-offset)) & 1
			bytes[written] = u8('0') + u8(bit)
			written += 1
		}
	}
	if output == nil || int(output_capacity) < written do return -2
	for index := 0; index < written; index += 1 { output[index] = bytes[index] }
	return i64(written)
}
