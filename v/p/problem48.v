module problem48

const modulus = i64(10_000_000_000)

@[export: 'problem48']
pub fn problem48(ignored i64) i64 {
	if ignored != 0 { return -1 }
	mut total := i64(0)
	mut base := i64(1)
	for base <= 1000 {
		mut term := i64(1)
		mut exponent := i64(0)
		for exponent < base {
			term = (term * base) % modulus
			exponent++
		}
		total = (total + term) % modulus
		base++
	}
	return total
}
