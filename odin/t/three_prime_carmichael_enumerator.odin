package three_prime_carmichael_enumerator

import "core:c"

MAX_LIMIT :: 61
MAX_TRIPLES :: 69

tpc_is_prime :: proc "contextless" (value: i64) -> bool {
	if value < 2 do return false
	if value % 2 == 0 do return value == 2
	divisor: i64 = 3
	for divisor <= value / divisor {
		if value % divisor == 0 do return false
		divisor += 2
	}
	return true
}

tpc_put_u32 :: proc "contextless" (output: [^]u8, offset: int, value: u32) {
	for byte := 0; byte < 4; byte += 1 {
		output[offset + byte] = u8((value >> u32(byte * 8)) & 255)
	}
}

@(export)
three_prime_carmichael_enumerator :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != c.size_t(1) do return -1
	limit := input[0]
	if limit < 2 || limit > MAX_LIMIT do return -1

	triples: [MAX_TRIPLES * 3]u32 = {}
	triple_count := 0
	for p1 := i64(2); p1 <= limit; p1 += 1 {
		if !tpc_is_prime(p1) do continue
		for h3 := i64(2); h3 < p1; h3 += 1 {
			g := h3 + p1
			for d := i64(1); d < g; d += 1 {
				if (g * (p1 - 1)) % d != 0 do continue
				negative_square_residue := (h3 - (p1 * p1) % h3) % h3
				if negative_square_residue != d % h3 do continue
				p2 := 1 + (p1 - 1) * g / d
				if p2 <= p1 || !tpc_is_prime(p2) do continue
				p3 := 1 + (p1 * p2) / h3
				if p3 <= p2 || !tpc_is_prime(p3) do continue
				if (p2 * p3) % (p1 - 1) != 1 do continue
				triples[triple_count * 3] = u32(p1)
				triples[triple_count * 3 + 1] = u32(p2)
				triples[triple_count * 3 + 2] = u32(p3)
				triple_count += 1
			}
		}
	}

	required := 4 + triple_count * 12
	if output == nil || capacity < c.size_t(required) do return -2
	tpc_put_u32(output, 0, u32(triple_count))
	for record := 0; record < triple_count; record += 1 {
		tpc_put_u32(output, 4 + record * 12, triples[record * 3])
		tpc_put_u32(output, 8 + record * 12, triples[record * 3 + 1])
		tpc_put_u32(output, 12 + record * 12, triples[record * 3 + 2])
	}
	return i64(required)
}
