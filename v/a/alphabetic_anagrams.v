module alphabetic_anagrams

const max_length = 8
const alphabet_size = 26

fn factorial(value i64) i64 {
	mut result := i64(1)
	for factor := i64(2); factor <= value; factor++ { result *= factor }
	return result
}

@[export: 'alphabetic_anagrams']
pub fn alphabetic_anagrams(input &i64, length usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > 10 { return -1 }
		n := input[0]
		if n < 0 || n > max_length || length != usize(n + 1) { return -1 }
		mut frequency := [26]i64{}
		for position in 0 .. int(n) {
			symbol := input[position + 1]
			if symbol < 0 || symbol > 25 { return -1 }
			frequency[int(symbol)]++
		}
		mut denominator := i64(1)
		for symbol in 0 .. alphabet_size { denominator *= factorial(frequency[symbol]) }
		mut ways := factorial(n) / denominator
		mut rank := i64(1)
		mut remaining := n
		for position in 0 .. int(n) {
			actual := int(input[position + 1])
			for smaller in 0 .. actual {
				if frequency[smaller] > 0 { rank += ways * frequency[smaller] / remaining }
			}
			ways = ways * frequency[actual] / remaining
			frequency[actual]--
			remaining--
		}
		return rank
	}
}
