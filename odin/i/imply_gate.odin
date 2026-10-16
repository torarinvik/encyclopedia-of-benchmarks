package imply_gate

@(export)
imply_gate :: proc "c" (left, right: u64) -> i64 {
	if left > 1 || right > 1 do return -1
	if left == 0 || right == 1 do return 1
	return 0
}
