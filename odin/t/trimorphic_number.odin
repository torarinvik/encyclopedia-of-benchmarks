package trimorphic_number

@(export)
trimorphic_number :: proc "c" (number: i64) -> i64 {
	if number < 0 || number > 2_000_000 do return -1
	modulus := i64(10)
	digits := number
	for digits >= 10 {
		digits /= 10
		modulus *= 10
	}
	cube := number * number * number
	if cube % modulus == number do return 1
	return 0
}
