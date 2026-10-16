module product_sum

struct Parser {
	tokens []i64
	mut:
		cursor int
		valid bool
}

fn (mut p Parser) parse(depth int, nested bool) i64 {
	if depth > 16 { p.valid = false; return 0 }
	mut total := i64(0)
	for p.cursor < p.tokens.len {
		x := p.tokens[p.cursor]
		p.cursor++
		if x == 2002 { if !nested { p.valid = false }; return total * i64(depth) }
		if x == 2001 { total += p.parse(depth + 1, true) }
		else if x >= -1000 && x <= 1000 { total += x }
		else { p.valid = false; return 0 }
		if !p.valid { return 0 }
	}
	if nested { p.valid = false }
	return total * i64(depth)
}

@[export: 'product_sum']
pub fn product_sum(v &i64, n usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != usize(v[0] + 1) { return -1 }
		mut p := Parser{tokens: unsafe { v[1..n] }, valid: true}
		answer := p.parse(1, false)
		if p.valid && p.cursor == p.tokens.len { return answer }
		return -1
	}
}
