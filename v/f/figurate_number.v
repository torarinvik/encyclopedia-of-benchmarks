module figurate_number

fn is_triangular(n i64) bool {
	mut i := i64(0)
	for i <= n {
		term := i * (i + 1) / 2
		if term == n { return true }
		if term > n { return false }
		i++
	}
	return false
}

fn is_tetrahedral(n i64) bool {
	mut i := i64(1)
	for i <= n {
		term := i * (i + 1) * (i + 2) / 6
		if term == n { return true }
		if term > n { return false }
		i++
	}
	return false
}

fn is_pentatope(n i64) bool {
	mut i := i64(1)
	for i <= n {
		term := i * (i + 1) * (i + 2) * (i + 3) / 24
		if term == n { return true }
		if term > n { return false }
		i++
	}
	return false
}

@[export: 'figurate_number']
pub fn figurate_number(n i64) i64 {
	if n < 0 || n > 1_000_000 { return -1 }
	mut result := i64(0)
	if is_triangular(n) { result += 1 }
	if is_tetrahedral(n) { result += 2 }
	if is_pentatope(n) { result += 4 }
	return result
}
