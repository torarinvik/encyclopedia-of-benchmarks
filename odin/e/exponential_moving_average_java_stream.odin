package exponential_moving_average_java_stream

import "core:c"

put_f64_le :: proc "contextless" (output: [^]u8, offset: usize, value: f64) {
	bits := transmute(u64)value
	for byte: u32 = 0; byte < 8; byte += 1 { output[offset+usize(byte)] = u8(bits >> (8*byte)) }
}
put_i64_le :: proc "contextless" (output: [^]u8, offset: usize, value: i64) {
	bits := u64(value)
	for byte: u32 = 0; byte < 8; byte += 1 { output[offset+usize(byte)] = u8(bits >> (8*byte)) }
}

@(export)
exponential_moving_average_java_stream :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 2 || input[1] < 0 || input[1] > 256 || length != c.size_t(2+input[1]) do return -1
	if input[0] < -1_000_000 || input[0] > 1_000_000 do return -1
	mean,variance := f64(input[0]),f64(0)
	for i: usize = 0; i < usize(input[1]); i += 1 {
		if input[i+2] < -1_000_000 || input[i+2] > 1_000_000 do return -1
		value:=f64(input[i+2]);deviation:=value-mean
		mean += 0.25*deviation
		variance=0.75*(variance+0.25*deviation*deviation)
	}
	if output==nil || capacity<24 do return -2
	put_f64_le(output,0,mean);put_f64_le(output,8,variance);put_i64_le(output,16,input[1])
	return 24
}
