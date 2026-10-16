package dice_thrower

import "core:c"

MAX_TARGET :: 8

required_bytes :: proc(remaining, depth: int) -> int {
	if remaining == 0 do return depth + 1
	total := 0
	maximum_face := min(remaining, 6)
	for face := 1; face <= maximum_face; face += 1 {
		total += required_bytes(remaining - face, depth + 1)
	}
	return total
}

emit_combinations :: proc(remaining, depth: int, digits: ^[MAX_TARGET]u8,
	output: [^]u8, position: ^int) {
	if remaining == 0 {
		for index := 0; index < depth; index += 1 {
			output[position^] = digits^[index]
			position^ += 1
		}
		output[position^] = '\n'
		position^ += 1
		return
	}
	maximum_face := min(remaining, 6)
	for face := 1; face <= maximum_face; face += 1 {
		digits^[depth] = u8('0' + face)
		emit_combinations(remaining - face, depth + 1, digits, output, position)
	}
}

@(export)
dice_thrower :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if values == nil || length != 1 || values[0] < 0 || values[0] > MAX_TARGET do return -1
	target := int(values[0])
	needed := required_bytes(target, 0)
	if int(output_capacity) < needed || output == nil do return -2
	var digits: [MAX_TARGET]u8
	position := 0
	emit_combinations(target, 0, &digits, output, &position)
	return i64(position)
}
