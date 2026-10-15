module can_string_be_rearranged_as_palindrome

// Can lowercase ASCII letters be rearranged into a palindrome?
@[export: 'can_string_be_rearranged_as_palindrome']
pub fn can_string_be_rearranged_as_palindrome(text &i64, length usize) i64 {
	if length == 0 || length > 4096 { return -1 }
	mut counts := [26]int{init: 0}
	mut odd_count := 0
	for index in 0 .. length {
		value := text[index]
		if value < 97 || value > 122 { return -1 }
		letter := int(value - 97)
		if counts[letter] % 2 == 0 { odd_count++ } else { odd_count-- }
		counts[letter]++
	}
	if odd_count <= 1 { return 1 }
	return 0
}
