module triangular_number

// Compute T(n) = n(n+1)/2 without an overflowing intermediate product.
@[export: 'triangular_number']
pub fn triangular_number(input i64) i64 {
	if input < 0 || input > 4_294_967_295 { return -1 }
	left := if input % 2 == 0 { input / 2 } else { input }
	right := if input % 2 == 0 { input + 1 } else { (input + 1) / 2 }
	return left * right
}
