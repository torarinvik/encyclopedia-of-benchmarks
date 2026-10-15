module trimorphic_number

@[export: 'trimorphic_number']
pub fn trimorphic_number(number i64) i64 {
	if number < 0 || number > 2_000_000 { return -1 }
	mut modulus := i64(10)
	mut digits := number
	for digits >= 10 {
		digits /= 10
		modulus *= 10
	}
	cube := number * number * number
	if cube % modulus == number { return 1 }
	return 0
}
