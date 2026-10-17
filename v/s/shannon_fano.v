module shannon_fano

const max_text_length = 64
const max_input_length = 66
const max_symbols = 10
const max_output_bytes = 111

struct Shannon_frame {
	start int
	finish int
	bits u16
	length int
}

@[export: 'shannon_fano_generate_codes']
pub fn shannon_fano_generate_codes(input &i64, input_length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		null_empty := input == nil && input_length == 0
		if input == nil && !null_empty { return -1 }
		mut text := [max_text_length]u8{}
		mut text_length := 0
		if !null_empty {
			if input_length < 1 || input_length > max_input_length { return -1 }
			length_value := input[0]
			if length_value < 0 || length_value > i64(max_text_length) { return -1 }
			text_length = int(length_value)
			if input_length != usize(1 + text_length) { return -1 }
			for index in 0 .. text_length {
				code := input[1 + index]
				if code < 0 || code > 127 { return -1 }
				text[index] = u8(code)
			}
		}

		mut frequencies := [128]int{}
		for index in 0 .. text_length { frequencies[text[index]]++ }
		mut symbols := [128]int{}
		mut symbol_count := 0
		for symbol in 0 .. 128 {
			if frequencies[symbol] > 0 {
				symbols[symbol_count] = symbol
				symbol_count++
			}
		}
		if symbol_count > max_symbols { return -1 }
		for left in 0 .. symbol_count {
			for right in left + 1 .. symbol_count {
				if frequencies[symbols[left]] == frequencies[symbols[right]] { return -1 }
			}
		}
		for index in 1 .. symbol_count {
			value := symbols[index]
			mut position := index
			for position > 0 && frequencies[symbols[position - 1]] < frequencies[value] {
				symbols[position] = symbols[position - 1]
				position--
			}
			symbols[position] = value
		}

		mut code_bits := [128]u16{}
		mut code_lengths := [128]int{}
		if symbol_count == 1 {
			code_lengths[symbols[0]] = 1
		} else if symbol_count > 1 {
			mut stack := [20]Shannon_frame{}
			mut stack_length := 1
			stack[0] = Shannon_frame{start: 0, finish: symbol_count - 1, bits: 0, length: 0}
			for stack_length > 0 {
				stack_length--
				frame := stack[stack_length]
				if frame.start == frame.finish {
					symbol := symbols[frame.start]
					code_bits[symbol] = frame.bits
					code_lengths[symbol] = frame.length
					continue
				}
				mut total := 0
				for index in frame.start .. frame.finish + 1 { total += frequencies[symbols[index]] }
				mut left_sum := 0
				mut best_difference := max_text_length + 1
				mut split := frame.start
				for index in frame.start .. frame.finish {
					left_sum += frequencies[symbols[index]]
					right_sum := total - left_sum
					mut difference := left_sum - right_sum
					if difference < 0 { difference = -difference }
					if difference < best_difference {
						best_difference = difference
						split = index
					}
				}
				next_length := frame.length + 1
				stack[stack_length] = Shannon_frame{start: split + 1, finish: frame.finish,
					bits: (frame.bits << 1) | 1, length: next_length}
				stack_length++
				stack[stack_length] = Shannon_frame{start: frame.start, finish: split,
					bits: frame.bits << 1, length: next_length}
				stack_length++
			}
		}

		mut bytes := [max_output_bytes]u8{}
		mut written := 0
		bytes[written] = u8(symbol_count)
		written++
		for symbol in 0 .. 128 {
			code_length := code_lengths[symbol]
			if code_length == 0 { continue }
			bytes[written] = u8(symbol)
			bytes[written + 1] = u8(code_length)
			written += 2
			for offset in 0 .. code_length {
				bit := (code_bits[symbol] >> u16(code_length - 1 - offset)) & 1
				bytes[written] = u8('0') + u8(bit)
				written++
			}
		}
		if output == nil || output_capacity < usize(written) { return -2 }
		for index in 0 .. written { output[index] = bytes[index] }
		return i64(written)
	}
}
