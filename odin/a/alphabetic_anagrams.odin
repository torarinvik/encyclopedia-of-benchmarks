package alphabetic_anagrams

import "core:c"

MAX_LENGTH :: 8
ALPHABET_SIZE :: 26

factorial :: proc(value: i64) -> i64 {
	result: i64 = 1
	for factor := i64(2); factor <= value; factor += 1 { result *= factor }
	return result
}

@(export, link_name="alphabetic_anagrams")
alphabetic_anagrams :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 1 || length > 10 do return -1
	n := input[0]
	if n < 0 || n > MAX_LENGTH || length != c.size_t(n + 1) do return -1
	frequency: [ALPHABET_SIZE]i64
	for symbol := 0; symbol < ALPHABET_SIZE; symbol += 1 { frequency[symbol] = 0 }
	for position := i64(0); position < n; position += 1 {
		symbol := input[position + 1]
		if symbol < 0 || symbol > 25 do return -1
		frequency[int(symbol)] += 1
	}
	denominator: i64 = 1
	for symbol := 0; symbol < ALPHABET_SIZE; symbol += 1 { denominator *= factorial(frequency[symbol]) }
	ways := factorial(n) / denominator
	rank: i64 = 1
	remaining := n
	for position := i64(0); position < n; position += 1 {
		actual := input[position + 1]
		for smaller := i64(0); smaller < actual; smaller += 1 {
			if frequency[int(smaller)] > 0 do rank += ways * frequency[int(smaller)] / remaining
		}
		frequency[int(actual)] -= 1
		ways = ways * (frequency[int(actual)] + 1) / remaining
		remaining -= 1
	}
	return rank
}
