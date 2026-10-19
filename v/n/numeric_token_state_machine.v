module numeric_token_state_machine
// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
// Apache-2.0 licensed upstream kernel, bounded variant; modifications made.
import math

const max_text = 96

fn scan_text(text &u8, n int, mut finals [8]u32, mut transitions [8]u32) {
	mut pos := 0
	for pos < n {
		mut state := 0
		for pos < n && state != 1 {
			ch := unsafe { text[pos] }
			if ch == `,` { pos++; break }
			digit := ch >= `0` && ch <= `9`
			match state {
				0 { if digit {state=4} else if ch==`+`||ch==`-` {state=2} else if ch==`.` {state=5} else {state=1;transitions[1]++}; transitions[0]++ }
				2 { if digit {state=4} else if ch==`.` {state=5} else {state=1}; transitions[2]++ }
				4 { if ch==`.` {state=5;transitions[4]++} else if !digit {state=1;transitions[4]++} }
				5 { if ch==`e`||ch==`E` {state=3;transitions[5]++} else if !digit {state=1;transitions[5]++} }
				3 { if ch==`+`||ch==`-` {state=6} else {state=1}; transitions[3]++ }
				6 { if digit {state=7} else {state=1}; transitions[6]++ }
				7 { if !digit {state=1;transitions[1]++} }
				else {}
			}
			pos++
		}
		finals[state]++
	}
}

@[export: 'numeric_token_state_machine']
pub fn numeric_token_state_machine(input &i64, length usize, output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length < 4 || length > usize(max_text+3) { return -1 }
		raw_n, step, seed := input[0], input[1], input[2]
		if raw_n < 1 || raw_n > max_text || length != usize(raw_n+3) || step < 1 || step > 16 || seed < 1 || seed > 255 { return -1 }
		n := int(raw_n)
		mut text := [max_text]u8{init: 0}
		for i in 0 .. n { if input[3+i] < 32 || input[3+i] > 126 { return -1 }; text[i] = u8(input[3+i]) }
		if text[0] == `,` || text[n-1] == `,` { return -1 }
		for i in 1 .. n { if text[i] == `,` && text[i-1] == `,` { return -1 } }
		for i := 0; i < n; i += int(step) { if text[i] != `,` && ((text[i] ^ u8(seed)) == `,` || (text[i] ^ u8(seed)) == 0) { return -1 } }
		mut finals := [8]u32{init: 0}
		mut transitions := [8]u32{init: 0}
		scan_text(&text[0],n,mut finals,mut transitions)
		for i := 0; i < n; i += int(step) { if text[i] != `,` { text[i] ^= u8(seed) } }
		scan_text(&text[0],n,mut finals,mut transitions)
		for i := 0; i < n; i += int(step) { if text[i] != `,` { text[i] ^= u8(seed) } }
		if output == nil || output_capacity < 64 { return -2 }
		for i in 0 .. 8 { for b in 0 .. 4 { output[i*8+b] = u8((finals[i] >> u32(8*b)) & 255); output[i*8+4+b] = u8((transitions[i] >> u32(8*b)) & 255) } }
		return 64
	}
}
