package euler_method_julia

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for byte: u32 = 0; byte < 8; byte += 1 { output[offset+usize(byte)] = u8(bits >> (8*byte)) }
}

@(export)
euler_method_julia :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil || length!=3 do return -1
	if input[0]<-8 || input[0]>8 || input[1]<1 || input[1]>16 || input[2]<1 || input[2]>4 do return -1
	steps:=usize(input[1]);required:=16*steps;if output==nil || capacity<c.size_t(required) do return -2
	h:=1.0/f64(1<<u32(input[2]))
	var states:[16]f64;var times:[16]f64;states[0]=f64(input[0]);times[0]=0
	for i:usize=0;i+1<steps;i+=1 { states[i+1]=states[i]+h*(states[i]+times[i]);times[i+1]=times[i]+h }
	for i:usize=0;i<steps;i+=1 { put_f64_le(output,8*i,states[i]);put_f64_le(output,8*(steps+i),times[i]) }
	return i64(required)
}
