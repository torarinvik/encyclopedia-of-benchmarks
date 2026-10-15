module euler_method

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits&255) }; bits >>= 8 }
}

@[export: 'euler_method']
pub fn euler_method(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 4 { return -1 }
	unsafe {
		if input[0] < -8 || input[0] > 8 || input[1] < -8 || input[1] > 8 || input[2] < 1 || input[2] > 4 || input[3] < 1 || input[3] > 16 { return -1 }
		steps:=int(input[3]);required:=8*(steps+1)
		if unsafe { output == nil } || capacity<required { return -2 }
		h:=1.0/f64(1<<u32(input[2]));mut x:=f64(input[0]);mut y:=f64(input[1])
		put_f64_le(mut output,0,y)
		for step in 0 .. steps { y=y+h*(x+y);x+=h;put_f64_le(mut output,8*(step+1),y) }
		return i64(required)
	}
}
