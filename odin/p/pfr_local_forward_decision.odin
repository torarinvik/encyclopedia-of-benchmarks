package pfr_local_forward_decision

import "core:c"

@(export)
pfr_local_forward_decision :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	angle, draw := input[0], input[1]
	if angle < 0 || angle > 180000000 || draw < 0 || draw >= 1000000 do return -1
	forward: i64 = 0
	if angle >= 134000000 || 180*draw < angle { forward = 1 }
	if output == nil || capacity < 8 do return -2
	bits := u64(forward)
	for byte := 0; byte < 8; byte += 1 { output[byte] = u8(bits & 255); bits >>= 8 }
	return 8
}
