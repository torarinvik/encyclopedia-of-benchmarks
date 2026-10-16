module nimply_gate

@[export: 'nimply_gate']
pub fn nimply_gate(values &i64, length usize) i64 {
	if length != 2 { return -1 }
	a := unsafe { values[0] }
	b := unsafe { values[1] }
	if (a != 0 && a != 1) || (b != 0 && b != 1) { return -1 }
	if a == 1 && b == 0 { return 1 }
	return 0
}
