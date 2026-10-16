package product_sum

import "core:c"

Parser :: struct { tokens: [^]i64, count, cursor: int, valid: bool }

parse_list :: proc "contextless" (p: ^Parser, depth: int, nested: bool) -> i64 {
	if depth > 16 { p.valid = false; return 0 }
	total := i64(0)
	for p.cursor < p.count {
		x := p.tokens[p.cursor]; p.cursor += 1
		if x == 2002 { if !nested do p.valid = false; return total * i64(depth) }
		if x == 2001 { total += parse_list(p, depth + 1, true) }
		else if x >= -1000 && x <= 1000 { total += x }
		else { p.valid = false; return 0 }
		if !p.valid do return 0
	}
	if nested do p.valid = false
	return total * i64(depth)
}

@(export)
product_sum :: proc "c" (v: [^]i64, n: c.size_t) -> i64 {
	if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != c.size_t(v[0] + 1) do return -1
	p := Parser{tokens = v + 1, count = int(v[0]), valid = true}
	answer := parse_list(&p, 1, false)
	if p.valid && p.cursor == p.count do return answer
	return -1
}
