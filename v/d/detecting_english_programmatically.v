@[export: 'detecting_english_programmatically']
pub fn detecting_english_programmatically(input &i64, length usize) i64 {
	if length < 1 || length > 172 { return -1 }
	mut p := usize(0)
	count := unsafe { input[p] }; p++
	if count < 0 || count > 8 { return -1 }
	mut starts := []usize{len: 8}
	mut lens := []usize{len: 8}
	for w in 0 .. int(count) {
		if p >= length { return -1 }
		l := unsafe { input[p] }; p++
		if l < 1 || l > 12 || p + usize(l) > length { return -1 }
		starts[w] = p; lens[w] = usize(l)
		for j in 0 .. int(l) { c := unsafe { input[p+usize(j)] }; if c < 65 || c > 90 { return -1 } }
		if w > 0 {
			mut k := usize(0)
			for k < lens[w-1] && k < lens[w] && unsafe { input[starts[w-1]+k] == input[p+k] } { k++ }
			if k == lens[w-1] && k == lens[w] { return -1 }
			if k == lens[w-1] && k < lens[w] {} else if k < lens[w-1] && k < lens[w] && unsafe { input[starts[w-1]+k] > input[p+k] } { return -1 }
			else if k < lens[w-1] && k == lens[w] { return -1 }
		}
		p += usize(l)
	}
	if p >= length { return -1 }
	m := unsafe { input[p] }; p++
	if m < 1 || m > 64 || p + usize(m) + 2 != length { return -1 }
	ms := p
	for j in 0 .. int(m) { c := unsafe { input[ms+usize(j)] }; if c < 0 || c > 127 { return -1 } }
	p += usize(m); wp := unsafe { input[p] }; lp := unsafe { input[p+1] }
	if wp < 0 || wp > 100 || lp < 0 || lp > 100 { return -1 }
	mut retained := i64(0); mut tokens := i64(0); mut hits := i64(0); mut i := usize(0); mut tok := []i64{cap: 64}
	for i <= usize(m) {
		mut c := if i < usize(m) { unsafe { input[ms+i] } } else { i64(32) }
		letter := (c >= 65 && c <= 90) || (c >= 97 && c <= 122)
		ws := c == 9 || c == 10 || c == 32
		if i < usize(m) && (letter || ws) { retained++ }
		if letter { tok << if c >= 97 { c - 32 } else { c }; i++; continue }
		if !ws { i++; continue }
		if tok.len == 0 { i++; continue }
		tokens++
		for w in 0 .. int(count) {
			if lens[w] != usize(tok.len) { continue }
			mut k := usize(0)
			for k < tok.len && unsafe { input[starts[w]+k] == tok[k] } { k++ }
			if k == usize(tok.len) { hits++; break }
		}
		tok.clear(); i++
	}
	if tokens > 0 && hits * 100 >= wp * tokens && retained * 100 >= lp * m { return 1 }
	return 0
}
