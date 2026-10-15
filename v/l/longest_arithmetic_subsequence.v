module longest_arithmetic_subsequence

// Length of the longest arithmetic subsequence.
@[export: 'longest_arithmetic_subsequence']
pub fn longest_arithmetic_subsequence(values &i64, length usize) i64 {
	if length > 64 { return -1 }
	for i in 0 .. length {
		value := unsafe { values[i] }
		if value < -1_000_000 || value > 1_000_000 { return -1 }
	}
	if length <= 1 { return i64(length) }
	mut keys := [64][127]i64{}
	mut sizes := [64][127]i64{}
	mut maximum := i64(2)
	for right in 0 .. length {
		for left in 0 .. right {
			difference := unsafe { values[right] - values[left] }
			hash := usize((difference % 127 + 127) % 127)
			mut slot := hash
			for sizes[left][slot] != 0 && keys[left][slot] != difference { slot = (slot + 1) % 127 }
			candidate := (if sizes[left][slot] == 0 { i64(1) } else { sizes[left][slot] }) + 1
			slot = hash
			for sizes[right][slot] != 0 && keys[right][slot] != difference { slot = (slot + 1) % 127 }
			if sizes[right][slot] == 0 || candidate > sizes[right][slot] {
				keys[right][slot] = difference
				sizes[right][slot] = candidate
			}
			if candidate > maximum { maximum = candidate }
		}
	}
	return maximum
}
