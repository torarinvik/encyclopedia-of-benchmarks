package kynea_numbers

@(export)
kynea_numbers :: proc "c" (index: i64) -> i64 {
	if index < 1 || index > 31 do return -1
	value := (i64(1) << u32(index)) + 1
	square := value * value
	return square - 2
}
