package euler_method

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for byte: u32 = 0; byte < 8; byte += 1 { output[offset+usize(byte)] = u8(bits >> (8*byte)) }
}

@(export)
euler_method :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 4 do return -1
	if input[0] < -8 || input[0] > 8 || input[1] < -8 || input[1] > 8 || input[2] < 1 || input[2] > 4 || input[3] < 1 || input[3] > 16 do return -1
	steps:=usize(input[3]);required:=8*(steps+1)
	if output==nil || capacity<c.size_t(required) do return -2
	h:=1.0/f64(1<<u32(input[2]));x:=f64(input[0]);y:=f64(input[1])
	put_f64_le(output,0,y)
	for step:usize=0;step<steps;step+=1 { y=y+h*(x+y);x+=h;put_f64_le(output,8*(step+1),y) }
	return i64(required)
}
