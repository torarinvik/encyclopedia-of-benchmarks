module exponential_moving_average_java_stream

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits>>(8*byte)) }; bits >>= 8 }
}
fn put_i64_le(mut output &u8, offset int, value i64) {
	mut bits:=u64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits>>(8*byte)) }; bits >>= 8 }
}

@[export: 'exponential_moving_average_java_stream']
pub fn exponential_moving_average_java_stream(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		if input[1] < 0 || input[1] > 256 || length != usize(2+input[1]) { return -1 }
		if input[0] < -1_000_000 || input[0] > 1_000_000 { return -1 }
		mut mean:=f64(input[0]);mut variance:=f64(0)
		for i in 0 .. int(input[1]) {
			if input[i+2] < -1_000_000 || input[i+2] > 1_000_000 { return -1 }
			value:=f64(input[i+2]);deviation:=value-mean
			mean += 0.25*deviation
			variance=0.75*(variance+0.25*deviation*deviation)
		}
		if unsafe { output == nil } || capacity < 24 { return -2 }
		put_f64_le(mut output,0,mean);put_f64_le(mut output,8,variance);put_i64_le(mut output,16,input[1])
		return 24
	}
}
