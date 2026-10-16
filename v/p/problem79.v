module problem79

const logins = [50]int{319, 680, 180, 690, 129, 620, 762, 689, 762, 318, 368, 710, 720, 710, 629, 168, 160, 689, 716, 731, 736, 729, 316, 729, 729, 710, 769, 290, 719, 680, 318, 389, 162, 289, 162, 718, 729, 319, 790, 680, 890, 362, 319, 760, 316, 729, 380, 319, 728, 716}

fn next_permutation(mut digits [10]int, length int) bool {
	mut pivot := length - 2
	for pivot >= 0 && digits[pivot] >= digits[pivot + 1] { pivot-- }
	if pivot < 0 { return false }
	mut successor := length - 1
	for digits[successor] <= digits[pivot] { successor-- }
	temp := digits[pivot]; digits[pivot] = digits[successor]; digits[successor] = temp
	mut left := pivot + 1
	mut right := length - 1
	for left < right { temp = digits[left]; digits[left] = digits[right]; digits[right] = temp; left++; right-- }
	return true
}

@[export: 'problem79']
pub fn problem79(placeholder i64) i64 {
	if placeholder != 0 { return -1 }
	mut present := [10]bool{}
	for login in logins {
		present[login / 100] = true
		present[(login / 10) % 10] = true
		present[login % 10] = true
	}
	mut digits := [10]int{}
	mut length := 0
	for digit in 0 .. 10 { if present[digit] { digits[length] = digit; length++ } }
	for {
		mut positions := [10]int{}
		for digit in 0 .. 10 { positions[digit] = -1 }
		for index in 0 .. length { positions[digits[index]] = index }
		mut satisfied := true
		for login in logins {
			first := login / 100
			second := (login / 10) % 10
			third := login % 10
			if !(positions[first] < positions[second] && positions[second] < positions[third]) { satisfied = false; break }
		}
		if satisfied {
			mut passcode := i64(0)
			for index in 0 .. length { passcode = passcode * 10 + i64(digits[index]) }
			return passcode
		}
		if !next_permutation(mut digits, length) { break }
	}
	return -1
}
