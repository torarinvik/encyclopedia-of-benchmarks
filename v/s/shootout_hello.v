const source_calls = i64(1)
const output_bytes = 13

@[export: 'shootout_hello']
pub fn shootout_hello(calls i64, mut output &u8, output_capacity usize) i64 {
	if calls != source_calls { return -1 }
	if unsafe { output == nil } || output_capacity < output_bytes { return -2 }
	message := 'hello world\n\n'.bytes()
	mut staged := [output_bytes]u8{}
	for index in 0 .. output_bytes { staged[index] = message[index] }
	unsafe { for index in 0 .. output_bytes { output[index] = staged[index] } }
	return output_bytes
}
