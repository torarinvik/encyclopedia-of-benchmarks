module de_bruijn_sequences

const max_order = 16
const max_cycle_length = 10000

fn fkm_generate(position int, period int, order int, alphabet int,
	mut work [17]u8, mut output &u8, mut emitted int) {
	if position > order {
		if order % period == 0 {
			for index in 1 .. period + 1 {
				unsafe { output[emitted] = u8(48 + work[index]) }
				emitted++
			}
		}
		return
	}
	work[position] = work[position-period]
	fkm_generate(position + 1, period, order, alphabet, mut work, mut output, mut emitted)
	for symbol := int(work[position-period]) + 1; symbol < alphabet; symbol++ {
		work[position] = u8(symbol)
		fkm_generate(position + 1, position, order, alphabet, mut work, mut output, mut emitted)
	}
}

@[export: 'de_bruijn_sequences']
pub fn de_bruijn_sequences(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		alphabet_value := input[0]
		order_value := input[1]
		if alphabet_value < 2 || alphabet_value > 10 || order_value < 1 || order_value > max_order { return -1 }
		alphabet := int(alphabet_value)
		order := int(order_value)
		mut cycle_length := 1
		for _ in 0 .. order {
			if cycle_length > max_cycle_length / alphabet { return -1 }
			cycle_length *= alphabet
		}
		output_length := cycle_length + order - 1
		if output == nil || output_capacity < usize(output_length) { return -2 }
		mut work := [17]u8{}
		mut emitted := 0
		fkm_generate(1, 1, order, alphabet, mut work, mut output, mut emitted)
		for index in 0 .. (order - 1) {
			output[cycle_length + index] = output[index]
		}
		return i64(output_length)
	}
}
