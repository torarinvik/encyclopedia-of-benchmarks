module imply_gate

@[export: 'imply_gate']
pub fn imply_gate(left u64, right u64) i64 {
	if left > 1 || right > 1 { return -1 }
	if left == 0 || right == 1 { return 1 }
	return 0
}
