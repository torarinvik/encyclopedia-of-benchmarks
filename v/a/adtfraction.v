module adtfraction

import math

fn wrap32(value i64) i32 {
	mut bits := value % 4294967296
	if bits > 2147483647 { bits -= 4294967296 }
	if bits < -2147483648 { bits += 4294967296 }
	return i32(bits)
}

fn pack(n i32, d i32) i64 {
	return i64(n) * 4294967296 + i64(u32(d))
}

@[export: 'adtfraction']
pub fn adtfraction(input &i64, length usize) i64 {
	if length != 5 { return -1 }
	for i in 0 .. 5 { if unsafe { input[i] } < -100000 || unsafe { input[i] } > 100000 { return -1 } }
	if unsafe { input[0] } < 0 || unsafe { input[0] } > 4 { return -1 }
	op := i32(unsafe { input[0] }); n := i32(unsafe { input[1] }); d := i32(unsafe { input[2] }); m := i32(unsafe { input[3] }); e := i32(unsafe { input[4] })
	if op == 0 { if d == 0 || e == 0 { return -1 }; den := wrap32(i64(d) * i64(e)); if den == 0 { return -1 }; num := wrap32(i64(d) * i64(m) + i64(n) * i64(e)); return pack(num, den) }
	if op == 1 { if d == 0 { return -1 }; return pack(wrap32(i64(n) * i64(m)), d) }
	if op == 2 { if d == 0 || e == 0 { return -1 }; den := wrap32(i64(d) * i64(e)); if den == 0 { return -1 }; return pack(wrap32(i64(n) * i64(m)), den) }
	if op == 3 { if n == 0 { return -1 }; return pack(d, n) }
	if d == 0 { return -1 }
	value := f32(n) / f32(d)
	return i64(math.f32_bits(value))
}
