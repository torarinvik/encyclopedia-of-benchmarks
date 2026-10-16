module primitive_root

// Search in ascending order for a full period of distinct residues.
@[export: 'primitive_root']
pub fn primitive_root(input &i64, length usize) i64 {
	if length != 1 || unsafe { input == nil } { return -1 }
	unsafe {
		if input[0] < 2 || input[0] > 127 { return -1 }
		modulus := int(input[0])
		for candidate in 1 .. modulus {
			mut seen := [127]bool{}
			mut power := 1
			mut distinct := true
			for _ in 0 .. modulus - 1 {
				if seen[power] { distinct = false; break }
				seen[power] = true
				power = (power * candidate) % modulus
			}
			if distinct { return i64(candidate) }
		}
		return 0
	}
}
