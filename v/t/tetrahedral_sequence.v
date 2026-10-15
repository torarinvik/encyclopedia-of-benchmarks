module tetrahedral_sequence

const max_index = i64(3810777)

@[export: 'tetrahedral_sequence']
pub fn tetrahedral_sequence(index i64) i64 {
	if index < 0 || index > max_index { return -1 }
	mut a := index
	mut b := index + 1
	mut c := index + 2
	if a % 2 == 0 { a /= 2 }
	else if b % 2 == 0 { b /= 2 }
	else { c /= 2 }
	if a % 3 == 0 { a /= 3 }
	else if b % 3 == 0 { b /= 3 }
	else { c /= 3 }
	return a * b * c
}
