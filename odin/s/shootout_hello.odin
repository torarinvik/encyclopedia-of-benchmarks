package shootout_hello

import "core:c"

SOURCE_CALLS :: i64(1)
OUTPUT_BYTES :: 13
SOURCE_OUTPUT :: "hello world\n\n"

@(export)
shootout_hello :: proc "c" (calls: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if calls != SOURCE_CALLS do return -1
	if output == nil || output_capacity < c.size_t(OUTPUT_BYTES) do return -2
	var staged: [OUTPUT_BYTES]u8
	source_bytes := transmute([]u8)SOURCE_OUTPUT
	for index := 0; index < OUTPUT_BYTES; index += 1 { staged[index] = source_bytes[index] }
	for index := 0; index < OUTPUT_BYTES; index += 1 { output[index] = staged[index] }
	return i64(OUTPUT_BYTES)
}
