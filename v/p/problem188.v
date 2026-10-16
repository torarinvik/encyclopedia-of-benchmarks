module problem188

fn modexpt(base i64, exponent i64, modulus i64) i64 {
	if exponent == 1 { return base }
	if exponent % 2 == 0 {
		half := modexpt(base, exponent / 2, modulus) % modulus
		return (half * half) % modulus
	}
	return (base * modexpt(base, exponent - 1, modulus)) % modulus
}

@[export: 'problem188']
pub fn problem188(base i64, height i64, digits i64) i64 {
	if base < 1 || base > 1000000000 || base % 10 == 0 || height < 1 || height > 10000 || digits < 1 || digits > 8 { return -1 }
	mut modulus := i64(1)
	for _ in 0 .. int(digits) { modulus *= 10 }
	mut result := base
	for _ in 1 .. int(height) { result = modexpt(base, result, modulus) }
	return result
}
