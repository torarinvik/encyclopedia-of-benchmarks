module prefix_to_infix

fn letter(x i64) bool { return (x >= 65 && x <= 90) || (x >= 97 && x <= 122) }
fn operator(x i64) bool { return x == 43 || x == 45 || x == 42 || x == 47 || x == 94 }
fn read16(p &u8, i int) int { unsafe { return int(p[i]) | (int(p[i + 1]) << 8) } }
fn write16(mut p &u8, i int, x int) { unsafe { p[i] = u8(x); p[i + 1] = u8(x >> 8) } }

@[export: 'prefix_to_infix']
pub fn prefix_to_infix(v &i64, n usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if v == nil || n < 1 || n > 64 || v[0] < 0 || v[0] > 63 || n != usize(v[0] + 1) { return -1 }
		if output == nil || capacity < 8192 { return -2 }
		count := int(v[0]); if count == 0 { return 0 }
		if count == 1 { if !letter(v[1]) { return -1 }; output[0] = u8(v[1]); return 1 }
		mut stack := 0; mut scratch := 256
		for i := count - 1; i >= 0; i-- {
			x := v[i + 1]
			if operator(x) {
				if stack < 2 { return -1 }
				l, r := stack - 2, stack - 1
				ls, ll := read16(output, l * 4), read16(output, l * 4 + 2)
				rs, rl := read16(output, r * 4), read16(output, r * 4 + 2)
				start := scratch; output[scratch] = 40; scratch++
				for j in 0 .. rl { output[scratch] = output[rs + j]; scratch++ }
				output[scratch] = u8(x); scratch++
				for j in 0 .. ll { output[scratch] = output[ls + j]; scratch++ }
				output[scratch] = 41; scratch++
				write16(mut output, l * 4, start); write16(mut output, l * 4 + 2, scratch - start); stack--
			} else {
				if !letter(x) { return -1 }
				write16(mut output, stack * 4, scratch); write16(mut output, stack * 4 + 2, 1); output[scratch] = u8(x); scratch++; stack++
			}
			if scratch > int(capacity) { return -2 }
		}
		if stack != 1 { return -1 }
		start, size := read16(output, 0), read16(output, 2)
		for i in 0 .. size { output[i] = output[start + i] }
		return i64(size)
	}
}
