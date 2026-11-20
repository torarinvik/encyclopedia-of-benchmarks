package caverphone_2_encoder

import "core:c"

MAX_TEXT :: 64
SCRATCH :: 128
CODE_BYTES :: 10

replace_all :: proc(text: []u8, length: ^int, old, replacement: string) {
	next: [SCRATCH]u8
	out := 0
	at := 0
	for at < length^ {
		matched := len(old) > 0 && at + len(old) <= length^
		if matched {
			for j in 0 .. len(old) { if text[at + j] != old[j] { matched = false } }
		}
		if matched {
			for j in 0 .. len(replacement) { next[out] = replacement[j]; out += 1 }
			at += len(old)
		} else { next[out] = text[at]; out += 1; at += 1 }
	}
	for i in 0 .. out { text[i] = next[i] }
	length^ = out
}

replace_prefix :: proc(text: []u8, length: ^int, old, replacement: string) {
	if length^ < len(old) do return
	for i in 0 .. len(old) { if text[i] != old[i] do return }
	tail := length^ - len(old)
	for i := tail; i > 0; i -= 1 { text[len(replacement) + i - 1] = text[len(old) + i - 1] }
	for i in 0 .. len(replacement) { text[i] = replacement[i] }
	length^ = len(replacement) + tail
}

replace_suffix :: proc(text: []u8, length: ^int, old, replacement: string) {
	if length^ < len(old) do return
	start := length^ - len(old)
	for i in 0 .. len(old) { if text[start + i] != old[i] do return }
	for i in 0 .. len(replacement) { text[start + i] = replacement[i] }
	length^ = start + len(replacement)
}

replace_char :: proc(text: []u8, length: int, old, replacement: u8) {
	for i in 0 .. length { if text[i] == old do text[i] = replacement }
}

squeeze :: proc(text: []u8, length: ^int, letter, marker: u8) {
	out := 0
	for i in 0 .. length^ {
		if text[i] == letter && out > 0 && text[out - 1] == marker do continue
		if text[i] == letter { text[out] = marker } else { text[out] = text[i] }
		out += 1
	}
	length^ = out
}

encode :: proc(values: [^]i64, result: ^[CODE_BYTES]u8) {
	text: [SCRATCH]u8
	n := int(values[0])
	for i in 0 .. n {
		code := values[i + 1]
		if code >= 65 && code <= 90 { code += 32 }
		text[i] = u8(code)
	}
	if n == 0 { for i in 0 .. CODE_BYTES { result[i] = '1' }; return }
	if text[n - 1] == 'e' do n -= 1
	view := text[:]
	replace_prefix(view, &n, "cough", "cou2f"); replace_prefix(view, &n, "rough", "rou2f")
	replace_prefix(view, &n, "tough", "tou2f"); replace_prefix(view, &n, "enough", "enou2f")
	replace_prefix(view, &n, "trough", "trou2f"); replace_prefix(view, &n, "gn", "2n")
	replace_suffix(view, &n, "mb", "m2")
	replace_all(view, &n, "cq", "2q"); replace_all(view, &n, "ci", "si")
	replace_all(view, &n, "ce", "se"); replace_all(view, &n, "cy", "sy"); replace_all(view, &n, "tch", "2ch")
	replace_char(view, n, 'c', 'k'); replace_char(view, n, 'q', 'k'); replace_char(view, n, 'x', 'k'); replace_char(view, n, 'v', 'f')
	replace_all(view, &n, "dg", "2g"); replace_all(view, &n, "tio", "sio"); replace_all(view, &n, "tia", "sia")
	replace_char(view, n, 'd', 't'); replace_all(view, &n, "ph", "fh"); replace_char(view, n, 'b', 'p')
	replace_all(view, &n, "sh", "s2"); replace_char(view, n, 'z', 's')
	if n > 0 && (text[0] == 'a' || text[0] == 'e' || text[0] == 'i' || text[0] == 'o' || text[0] == 'u') { text[0] = 'A' }
	for i in 0 .. n { if text[i] == 'a' || text[i] == 'e' || text[i] == 'i' || text[i] == 'o' || text[i] == 'u' do text[i] = '3' }
	replace_char(view, n, 'j', 'y'); replace_prefix(view, &n, "y3", "Y3"); replace_prefix(view, &n, "y", "A"); replace_char(view, n, 'y', '3')
	replace_all(view, &n, "3gh3", "3kh3"); replace_all(view, &n, "gh", "22"); replace_char(view, n, 'g', 'k')
	squeeze(view, &n, 's', 'S'); squeeze(view, &n, 't', 'T'); squeeze(view, &n, 'p', 'P'); squeeze(view, &n, 'k', 'K')
	squeeze(view, &n, 'f', 'F'); squeeze(view, &n, 'm', 'M'); squeeze(view, &n, 'n', 'N')
	replace_all(view, &n, "w3", "W3"); replace_all(view, &n, "wh3", "Wh3")
	replace_suffix(view, &n, "w", "3"); replace_char(view, n, 'w', '2'); replace_prefix(view, &n, "h", "A"); replace_char(view, n, 'h', '2')
	replace_all(view, &n, "r3", "R3"); replace_suffix(view, &n, "r", "3"); replace_char(view, n, 'r', '2')
	replace_all(view, &n, "l3", "L3"); replace_suffix(view, &n, "l", "3"); replace_char(view, n, 'l', '2')
	out := 0
	for i in 0 .. n { if text[i] != '2' { text[out] = text[i]; out += 1 } }
	n = out
	replace_suffix(view, &n, "3", "A")
	out = 0
	for i in 0 .. n { if text[i] != '3' { text[out] = text[i]; out += 1 } }
	n = out
	for i in 0 .. CODE_BYTES { result[i] = if i < n do text[i] else '1' }
}

@(export)
caverphone_2_encoder :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 1 || length > MAX_TEXT + 1 do return -1
	count := input[0]
	if count < 0 || count > MAX_TEXT || length != c.size_t(count + 1) do return -1
	for i in 0 .. int(count) {
		code := input[i + 1]
		if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) do return -1
	}
	if output == nil || output_capacity < CODE_BYTES do return -2
	result: [CODE_BYTES]u8
	encode(input, &result)
	for i in 0 .. CODE_BYTES { output[i] = result[i] }
	return CODE_BYTES
}
