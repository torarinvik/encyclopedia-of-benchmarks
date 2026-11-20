module balanced_parenthesis_rank_unrank

const max_pairs = 10
const max_input_length = 23
const ways_stride = 11
const ways_count = 231

@[export: 'balanced_parenthesis_rank_unrank']
pub fn balanced_parenthesis_rank_unrank(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 2 || length > max_input_length { return -1 }
		mode := input[0]
		pairs_value := input[1]
		if pairs_value < 1 || pairs_value > max_pairs { return -1 }
		pairs := int(pairs_value)
		sequence_length := 2 * pairs
		if mode == 0 {
			if int(length) != 2 + sequence_length { return -1 }
			mut balance := 0
			for index in 0 .. sequence_length {
				symbol := input[2 + index]
				if symbol != 0 && symbol != 1 { return -1 }
				if symbol == 0 { balance++ } else { balance-- }
				if balance < 0 { return -1 }
			}
			if balance != 0 { return -1 }
		} else if mode == 1 {
			if length != 3 { return -1 }
		} else {
			return -1
		}

		mut ways := [ways_count]i64{}
		ways[0] = 1
		for remaining in 1 .. sequence_length + 1 {
			for balance in 0 .. pairs + 1 {
				mut count := i64(0)
				if balance < pairs { count += ways[(remaining - 1) * ways_stride + balance + 1] }
				if balance > 0 { count += ways[(remaining - 1) * ways_stride + balance - 1] }
				ways[remaining * ways_stride + balance] = count
			}
		}

		if mode == 0 {
			mut rank := i64(0)
			mut balance := 0
			for index in 0 .. sequence_length {
				symbol := input[2 + index]
				remaining := sequence_length - index - 1
				if symbol == 1 && balance < pairs {
					rank += ways[remaining * ways_stride + balance + 1]
				}
				if symbol == 0 { balance++ } else { balance-- }
			}
			return rank
		}

		mut rank := input[2]
		if rank < 0 || rank >= ways[sequence_length * ways_stride] { return -1 }
		mut balance := 0
		mut code := i64(0)
		for index in 0 .. sequence_length {
			remaining := sequence_length - index - 1
			opening_count := if balance < pairs { ways[remaining * ways_stride + balance + 1] } else { i64(0) }
			if rank < opening_count {
				balance++
				code = code << 1
			} else {
				rank -= opening_count
				balance--
				code = (code << 1) | 1
			}
		}
		return code
	}
}
