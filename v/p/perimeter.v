module perimeter

@[export: 'perimeter']
pub fn perimeter(values &i64, length usize) i64 {
	if length != 2 || unsafe { values == nil } { return -1 }
	unsafe {
		sides := values[0]
		side_length := values[1]
		if sides < 3 || sides > 256 || side_length < 1 || side_length > 255 { return -1 }
		return sides * side_length
	}
}
