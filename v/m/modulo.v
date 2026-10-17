module modulo

// Bounded unsigned modulo matching TheAlgorithms/Solidity Modulo.GetModulo.
@[export: 'modulo']
pub fn modulo(values &i64, length usize) i64 {
	if length != 2 || unsafe { values == nil } { return -1 }
	unsafe {
		a := values[0]
		b := values[1]
		if a < 0 || a > 4_294_967_295 || b < 1 || b > 4_294_967_295 { return -1 }
		return a % b
	}
}
