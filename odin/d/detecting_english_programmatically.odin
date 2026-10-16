package detecting_english_programmatically

@(export)
detecting_english_programmatically :: proc(input: [^]i64, length: uint) -> i64 {
	if input == nil || length < 1 || length > 172 do return -1
	 n := int(length); p := 0; count := input[p]; p += 1
	if count < 0 || count > 8 do return -1
	starts: [8]int; lens: [8]int
	for w in 0..<int(count) {
		if p >= n do return -1
		l := input[p]; p += 1
		if l < 1 || l > 12 || p+int(l) > n do return -1
		starts[w] = p; lens[w] = int(l)
		for j in 0..<int(l) { if input[p+j] < 65 || input[p+j] > 90 do return -1 }
		if w > 0 {
			k := 0
			for k < lens[w-1] && k < lens[w] && input[starts[w-1]+k] == input[p+k] { k += 1 }
			if k == lens[w-1] && k == lens[w] do return -1
			if k == lens[w-1] && k < lens[w] {} else if k < lens[w-1] && k < lens[w] && input[starts[w-1]+k] > input[p+k] do return -1
			else if k < lens[w-1] && k == lens[w] do return -1
		}
		p += int(l)
	}
	if p >= n do return -1
	m := input[p]; p += 1
	if m < 1 || m > 64 || p+int(m)+2 != n do return -1
	ms := p
	for j in 0..<int(m) { if input[ms+j] < 0 || input[ms+j] > 127 do return -1 }
	p += int(m); wp := input[p]; lp := input[p+1]
	if wp < 0 || wp > 100 || lp < 0 || lp > 100 do return -1
	retained: i64 = 0
	tokens: i64 = 0
	hits: i64 = 0
	i: int = 0
	tok: [64]i64; tlen := 0
	for i <= int(m) {
		c := i64(32); if i < int(m) { c = input[ms+i] }; letter := (c >= 65 && c <= 90) || (c >= 97 && c <= 122); ws := c == 9 || c == 10 || c == 32
		if i < int(m) && (letter || ws) { retained += 1 }
		if letter { tok[tlen] = c; if c >= 97 { tok[tlen] -= 32 }; tlen += 1; i += 1; continue }
		if !ws { i += 1; continue }
		if tlen == 0 { i += 1; continue }
		tokens += 1
		for w in 0..<int(count) {
			if lens[w] != tlen do continue
			k := 0; for k < tlen && input[starts[w]+k] == tok[k] { k += 1 }
			if k == tlen { hits += 1; break }
		}
		tlen = 0; i += 1
	}
	if tokens == 0 do return -1
	if hits*100 >= wp*tokens && retained*100 >= lp*m do return 1
	return 0
}
