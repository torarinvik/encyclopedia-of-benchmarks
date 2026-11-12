package de_bruijn_sequences

import "core:c"

MAX_ORDER :: 16
MAX_CYCLE_LENGTH :: 10_000

fkm_generate :: proc(position, period, order, alphabet: int,
	work: [^]u8, output: [^]u8, emitted: ^int) {
	if position > order {
		if order % period == 0 {
			for index := 1; index <= period; index += 1 {
				output[emitted^] = u8(48 + work[index])
				emitted^ += 1
			}
		}
		return
	}
	work[position] = work[position-period]
	fkm_generate(position+1, period, order, alphabet, work, output, emitted)
	for symbol := int(work[position-period])+1; symbol < alphabet; symbol += 1 {
		work[position] = u8(symbol)
		fkm_generate(position+1, position, order, alphabet, work, output, emitted)
	}
}

@(export)
de_bruijn_sequences :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	alphabet_value, order_value := input[0], input[1]
	if alphabet_value < 2 || alphabet_value > 10 || order_value < 1 || order_value > MAX_ORDER do return -1
	alphabet, order := int(alphabet_value), int(order_value)
	cycle_length := 1
	for _ := 0; _ < order; _ += 1 {
		if cycle_length > MAX_CYCLE_LENGTH/alphabet do return -1
		cycle_length *= alphabet
	}
	output_length := cycle_length + order - 1
	if output == nil || output_capacity < c.size_t(output_length) do return -2
	work: [MAX_ORDER+1]u8 = {}
	emitted := 0
	fkm_generate(1, 1, order, alphabet, &work[0], output, &emitted)
	for index := 0; index+1 < order; index += 1 {
		output[cycle_length+index] = output[index]
	}
	return i64(output_length)
}
