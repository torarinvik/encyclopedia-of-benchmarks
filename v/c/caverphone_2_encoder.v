module caverphone_2_encoder

const max_text = 64
const scratch = 128
const code_bytes = 10

fn replace_all(mut text []u8, mut length &int, old string, replacement string) {
	mut next := [scratch]u8{}
	mut out := 0
	mut at := 0
	for at < *length {
		mut matched := old.len > 0 && at + old.len <= *length
		if matched {
			for j in 0 .. old.len { if text[at + j] != old[j] { matched = false } }
		}
		if matched {
			for j in 0 .. replacement.len { next[out] = replacement[j]; out++ }
			at += old.len
		} else { next[out] = text[at]; out++; at++ }
	}
	for i in 0 .. out { text[i] = next[i] }
	*length = out
}

fn replace_prefix(mut text []u8, mut length &int, old string, replacement string) {
	if *length < old.len { return }
	for i in 0 .. old.len { if text[i] != old[i] { return } }
	tail := *length - old.len
	for i := tail; i > 0; i-- { text[replacement.len + i - 1] = text[old.len + i - 1] }
	for i in 0 .. replacement.len { text[i] = replacement[i] }
	*length = replacement.len + tail
}

fn replace_suffix(mut text []u8, mut length &int, old string, replacement string) {
	if *length < old.len { return }
	start := *length - old.len
	for i in 0 .. old.len { if text[start + i] != old[i] { return } }
	for i in 0 .. replacement.len { text[start + i] = replacement[i] }
	*length = start + replacement.len
}

fn replace_char(mut text []u8, length int, old u8, replacement u8) {
	for i in 0 .. length { if text[i] == old { text[i] = replacement } }
}

fn squeeze(mut text []u8, mut length &int, letter u8, marker u8) {
	mut out := 0
	for i in 0 .. *length {
		if text[i] == letter && out > 0 && text[out - 1] == marker { continue }
		text[out] = if text[i] == letter { marker } else { text[i] }
		out++
	}
	*length = out
}

fn encode(input &i64) [code_bytes]u8 {
	mut text := [scratch]u8{}
	mut n := int(unsafe { input[0] })
	for i in 0 .. n {
		mut code := unsafe { input[i + 1] }
		if code >= 65 && code <= 90 { code += 32 }
		text[i] = u8(code)
	}
	mut result := [code_bytes]u8{init: `1`}
	if n == 0 { return result }
	if text[n - 1] == `e` { n-- }
	mut view := text[..]
	replace_prefix(mut view, mut n, 'cough', 'cou2f'); replace_prefix(mut view, mut n, 'rough', 'rou2f')
	replace_prefix(mut view, mut n, 'tough', 'tou2f'); replace_prefix(mut view, mut n, 'enough', 'enou2f')
	replace_prefix(mut view, mut n, 'trough', 'trou2f'); replace_prefix(mut view, mut n, 'gn', '2n')
	replace_suffix(mut view, mut n, 'mb', 'm2')
	replace_all(mut view, mut n, 'cq', '2q'); replace_all(mut view, mut n, 'ci', 'si')
	replace_all(mut view, mut n, 'ce', 'se'); replace_all(mut view, mut n, 'cy', 'sy'); replace_all(mut view, mut n, 'tch', '2ch')
	replace_char(mut view, n, `c`, `k`); replace_char(mut view, n, `q`, `k`); replace_char(mut view, n, `x`, `k`); replace_char(mut view, n, `v`, `f`)
	replace_all(mut view, mut n, 'dg', '2g'); replace_all(mut view, mut n, 'tio', 'sio'); replace_all(mut view, mut n, 'tia', 'sia')
	replace_char(mut view, n, `d`, `t`); replace_all(mut view, mut n, 'ph', 'fh'); replace_char(mut view, n, `b`, `p`)
	replace_all(mut view, mut n, 'sh', 's2'); replace_char(mut view, n, `z`, `s`)
	if n > 0 && (text[0] == `a` || text[0] == `e` || text[0] == `i` || text[0] == `o` || text[0] == `u`) { text[0] = `A` }
	for i in 0 .. n { if text[i] == `a` || text[i] == `e` || text[i] == `i` || text[i] == `o` || text[i] == `u` { text[i] = `3` } }
	replace_char(mut view, n, `j`, `y`); replace_prefix(mut view, mut n, 'y3', 'Y3'); replace_prefix(mut view, mut n, 'y', 'A'); replace_char(mut view, n, `y`, `3`)
	replace_all(mut view, mut n, '3gh3', '3kh3'); replace_all(mut view, mut n, 'gh', '22'); replace_char(mut view, n, `g`, `k`)
	squeeze(mut view, mut n, `s`, `S`); squeeze(mut view, mut n, `t`, `T`); squeeze(mut view, mut n, `p`, `P`); squeeze(mut view, mut n, `k`, `K`)
	squeeze(mut view, mut n, `f`, `F`); squeeze(mut view, mut n, `m`, `M`); squeeze(mut view, mut n, `n`, `N`)
	replace_all(mut view, mut n, 'w3', 'W3'); replace_all(mut view, mut n, 'wh3', 'Wh3')
	replace_suffix(mut view, mut n, 'w', '3'); replace_char(mut view, n, `w`, `2`); replace_prefix(mut view, mut n, 'h', 'A'); replace_char(mut view, n, `h`, `2`)
	replace_all(mut view, mut n, 'r3', 'R3'); replace_suffix(mut view, mut n, 'r', '3'); replace_char(mut view, n, `r`, `2`)
	replace_all(mut view, mut n, 'l3', 'L3'); replace_suffix(mut view, mut n, 'l', '3'); replace_char(mut view, n, `l`, `2`)
	mut out := 0
	for i in 0 .. n { if text[i] != `2` { text[out] = text[i]; out++ } }
	n = out
	replace_suffix(mut view, mut n, '3', 'A')
	out = 0
	for i in 0 .. n { if text[i] != `3` { text[out] = text[i]; out++ } }
	for i in 0 .. code_bytes { if i < out { result[i] = text[i] } }
	return result
}

@[export: 'caverphone_2_encoder']
pub fn caverphone_2_encoder(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if input == nil || length < 1 || length > max_text + 1 { return -1 }
	unsafe {
		count := input[0]
		if count < 0 || count > max_text || length != usize(count + 1) { return -1 }
		for i in 0 .. int(count) {
			code := input[i + 1]
			if !((code >= 65 && code <= 90) || (code >= 97 && code <= 122)) { return -1 }
		}
		if output == nil || output_capacity < code_bytes { return -2 }
		result := encode(input)
		for i in 0 .. code_bytes { output[i] = result[i] }
	}
	return code_bytes
}
