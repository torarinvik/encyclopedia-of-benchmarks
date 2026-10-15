module isogram

// Check whether ASCII letters form an isogram, ignoring case and spaces.
@[export: 'isogram']
pub fn isogram(values &i64, length usize) i64 {
	if length > 4096 { return -1 }
	mut seen := [26]bool{}
	for index in 0 .. length {
		mut value := unsafe { values[index] }
		if value == 32 { continue }
		if value >= 65 && value <= 90 { value += 32 }
		if value < 97 || value > 122 { return -1 }
		letter := int(value - 97)
		if seen[letter] { return 0 }
		seen[letter] = true
	}
	return 1
}
