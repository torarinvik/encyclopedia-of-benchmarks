module kynea_numbers

@[export: 'kynea_numbers']
pub fn kynea_numbers(index i64) i64 {
	if index < 1 || index > 31 { return -1 }
	value := (i64(1) << u32(index)) + 1
	square := value * value
	return square - 2
}
