package versabench_dbms_keys_union
import "core:c"

MAX_COUNT :: 16
MAX_INPUT_LENGTH :: 1 + 8 * MAX_COUNT

write_i64_le :: proc "contextless" (output: [^]u8, index: int, value: i64) {
	bits := u64(value)
	for b := 0; b < 8; b += 1 { output[index*8+b] = u8((bits >> u64(8*b)) & 255) }
}

@(export, link_name="versabench_dbms_keys_union")
versabench_dbms_keys_union :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH+1) do return -1
	raw_count := values[0]
	if raw_count < 1 || raw_count > MAX_COUNT || length != c.size_t(1+8*int(raw_count)) do return -1
	bounds: [8]i64
	for d := 0; d < 4; d += 1 { bounds[d] = values[1+d]; bounds[4+d] = values[5+d] }
	for i := 0; i < int(raw_count); i += 1 {
		at := 1+8*i
		for d := 0; d < 4; d += 1 {
			lo := values[at+d]; hi := values[at+4+d]
			if lo < -8 || lo > 8 || hi < -8 || hi > 8 || lo > hi do return -1
			if lo < bounds[d] do bounds[d] = lo
			if hi > bounds[4+d] do bounds[4+d] = hi
		}
	}
	if output == nil || output_capacity < 64 do return -2
	for i := 0; i < 8; i += 1 { write_i64_le(output, i, bounds[i]) }
	return 64
}
