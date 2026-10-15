module euler_method_julia

import math

fn put_f64_le(mut output &u8, offset int, value f64) {
	mut bits:=math.bits_from_f64(value)
	for byte in 0 .. 8 { unsafe { output[offset+byte]=u8(bits&255) };bits>>=8 }
}

@[export: 'euler_method_julia']
pub fn euler_method_julia(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input==nil } || length!=3 { return -1 }
	unsafe {
		if input[0]<-8 || input[0]>8 || input[1]<1 || input[1]>16 || input[2]<1 || input[2]>4 { return -1 }
		steps:=int(input[1]);required:=16*steps;if unsafe { output==nil } || capacity<required { return -2 }
		h:=1.0/f64(1<<u32(input[2]));mut states:=[16]f64{};mut times:=[16]f64{};states[0]=f64(input[0])
		for i in 0 .. steps-1 { states[i+1]=states[i]+h*(states[i]+times[i]);times[i+1]=times[i]+h }
		for i in 0 .. steps { put_f64_le(mut output,8*i,states[i]);put_f64_le(mut output,8*(steps+i),times[i]) }
		return i64(required)
	}
}
