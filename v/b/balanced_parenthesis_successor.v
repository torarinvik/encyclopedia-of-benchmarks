// Clean-room bounded lexicographic successor for a one-type Dyck word.
@[export: 'balanced_parenthesis_successor']
pub fn balanced_parenthesis_successor(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 21 { return -1 }
		pair_value := input[0]
		if pair_value < 1 || pair_value > 10 { return -1 }
		pairs := int(pair_value)
		sequence_length := 2*pairs
		if length != usize(1+sequence_length) { return -1 }
		mut symbols := []int{len: 20, init: 0}
		mut balance := 0
		for i in 0 .. sequence_length {
			symbol := input[1+i]
			if symbol != 0 && symbol != 1 { return -1 }
			symbols[i] = int(symbol)
			if symbol == 0 { balance++ } else { balance-- }
			if balance < 0 { return -1 }
		}
		if balance != 0 { return -1 }
		if output == nil || capacity < usize(sequence_length) { return -2 }

		mut staged := []u8{len: 20, init: 0}
		mut reverse_depth := 0
		mut cursor := sequence_length
		for cursor > 0 {
			cursor--
			if symbols[cursor] == 0 { reverse_depth-- } else { reverse_depth++ }
			if symbols[cursor] == 0 && reverse_depth > 0 {
				reverse_depth--
				suffix_length := sequence_length-cursor-1
				opening_count := (suffix_length-reverse_depth)/2
				closing_count := suffix_length-opening_count
				for j in 0 .. cursor { staged[j] = if symbols[j] == 0 { 40 } else { 41 } }
				staged[cursor] = 41
				mut position := cursor+1
				for _ in 0 .. opening_count { staged[position] = 40; position++ }
				for _ in 0 .. closing_count { staged[position] = 41; position++ }
				for j in 0 .. sequence_length { output[j] = staged[j] }
				return i64(sequence_length)
			}
		}
		return -3
	}
}
