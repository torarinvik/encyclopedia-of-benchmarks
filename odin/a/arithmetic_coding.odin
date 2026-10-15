package arithmetic_coding

import "core:c"

MAX_SYMBOLS :: 12
ALPHABET_SIZE :: 256

@(export)
arithmetic_coding :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	if input == nil || length < 2 do return -1
	count := input[0]
	if count < 1 || count > MAX_SYMBOLS || length != c.size_t(count + 1) do return -1

	frequency: [ALPHABET_SIZE]i64
	cumulative: [ALPHABET_SIZE + 1]i64
	for symbol := 0; symbol < ALPHABET_SIZE; symbol += 1 {
		frequency[symbol] = 0
		cumulative[symbol] = 0
	}
	cumulative[ALPHABET_SIZE] = 0
	for index := 0; index < int(count); index += 1 {
		symbol := input[index + 1]
		if symbol < 0 || symbol >= ALPHABET_SIZE do return -1
		frequency[int(symbol)] += 1
	}
	for symbol := 0; symbol < ALPHABET_SIZE; symbol += 1 {
		cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol]
	}

	low, high: i64 = 0, 1
	for index := 0; index < int(count); index += 1 {
		symbol := int(input[index + 1])
		range := high - low
		base := low * count
		high = base + range * cumulative[symbol + 1]
		low = base + range * cumulative[symbol]
	}
	return low
}
