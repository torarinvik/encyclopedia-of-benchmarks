package numeric_token_state_machine
import "core:c"
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
MAX_TEXT :: 96

scan_text :: proc(text: ^[MAX_TEXT]u8, n: int, finals: ^[8]u32, transitions: ^[8]u32) {
	pos := 0
	for pos < n {
		state := 0
		for pos < n && state != 1 {
			ch := text[pos]
			if ch == u8(',') { pos += 1; break }
			digit := ch >= u8('0') && ch <= u8('9')
			switch state {
			case 0: if digit {state=4} else if ch==u8('+')||ch==u8('-') {state=2} else if ch==u8('.') {state=5} else {state=1;transitions[1]+=1}; transitions[0]+=1
			case 2: if digit {state=4} else if ch==u8('.') {state=5} else {state=1}; transitions[2]+=1
			case 4: if ch==u8('.') {state=5;transitions[4]+=1} else if !digit {state=1;transitions[4]+=1}
			case 5: if ch==u8('e')||ch==u8('E') {state=3;transitions[5]+=1} else if !digit {state=1;transitions[5]+=1}
			case 3: if ch==u8('+')||ch==u8('-') {state=6} else {state=1}; transitions[3]+=1
			case 6: if digit {state=7} else {state=1}; transitions[6]+=1
			case 7: if !digit {state=1;transitions[1]+=1}
			}
			pos += 1
		}
		finals[state] += 1
	}
}

@(export)
numeric_token_state_machine :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_TEXT+3) do return -1
	raw_n, step, seed := input[0], input[1], input[2]
	if raw_n < 1 || raw_n > MAX_TEXT || length != c.size_t(raw_n+3) || step < 1 || step > 16 || seed < 1 || seed > 255 do return -1
	n := int(raw_n)
	text: [MAX_TEXT]u8
	for i := 0; i < n; i += 1 { if input[3+i] < 32 || input[3+i] > 126 do return -1; text[i] = u8(input[3+i]) }
	if text[0] == u8(',') || text[n-1] == u8(',') do return -1
	for i := 1; i < n; i += 1 { if text[i] == u8(',') && text[i-1] == u8(',') do return -1 }
	for i := 0; i < n; i += int(step) { if text[i] != u8(',') && ((text[i] ^ u8(seed)) == u8(',') || (text[i] ^ u8(seed)) == 0) do return -1 }
	finals: [8]u32 = {}
	transitions: [8]u32 = {}
	scan_text(&text,n,&finals,&transitions)
	for i := 0; i < n; i += int(step) { if text[i] != u8(',') do text[i] ^= u8(seed) }
	scan_text(&text,n,&finals,&transitions)
	for i := 0; i < n; i += int(step) { if text[i] != u8(',') do text[i] ^= u8(seed) }
	if output == nil || capacity < 64 do return -2
	for i := 0; i < 8; i += 1 { for b := 0; b < 4; b += 1 { output[i*8+b] = u8(finals[i] >> u32(8*b)); output[i*8+4+b] = u8(transitions[i] >> u32(8*b)) } }
	return 64
}
