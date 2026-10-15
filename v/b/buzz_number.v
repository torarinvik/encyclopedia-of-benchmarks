module buzz_number

@[export: 'buzz_number']
pub fn buzz_number(n i64) i64 {
	if n % 7 == 0 { return 1 }
	if n >= 0 && n % 10 == 7 { return 1 }
	return 0
}
