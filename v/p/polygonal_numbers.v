module polygonal_numbers

@[export: 'polygonal_numbers']
pub fn polygonal_numbers(packed &i64, length usize) i64 {
	if length != 2 { return -1 }
	num := unsafe { packed[0] }
	sides := unsafe { packed[1] }
	if num < 0 || num > 100000000 || sides < 3 || sides > 64 { return -1 }
	square := num * num
	leading := (sides - 2) * square
	trailing := (sides - 4) * num
	return (leading - trailing) / 2
}
