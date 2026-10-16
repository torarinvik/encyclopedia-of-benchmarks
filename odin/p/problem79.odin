package problem79

LOGINS :: [50]int{319, 680, 180, 690, 129, 620, 762, 689, 762, 318, 368, 710, 720, 710, 629, 168, 160, 689, 716, 731, 736, 729, 316, 729, 729, 710, 769, 290, 719, 680, 318, 389, 162, 289, 162, 718, 729, 319, 790, 680, 890, 362, 319, 760, 316, 729, 380, 319, 728, 716}

next_permutation :: proc(digits: ^[10]int, length: int) -> bool {
	pivot := length - 2
	for pivot >= 0 && digits[pivot] >= digits[pivot + 1] { pivot -= 1 }
	if pivot < 0 do return false
	successor := length - 1
	for digits[successor] <= digits[pivot] { successor -= 1 }
	temporary := digits[pivot]; digits[pivot] = digits[successor]; digits[successor] = temporary
	left := pivot + 1
	right := length - 1
	for left < right { temporary = digits[left]; digits[left] = digits[right]; digits[right] = temporary; left += 1; right -= 1 }
	return true
}

@(export)
problem79 :: proc "c" (placeholder: i64) -> i64 {
	if placeholder != 0 do return -1
	present: [10]bool
	for login in LOGINS {
		present[login / 100] = true
		present[(login / 10) % 10] = true
		present[login % 10] = true
	}
	digits: [10]int
	length := 0
	for digit := 0; digit < 10; digit += 1 { if present[digit] { digits[length] = digit; length += 1 } }
	for {
		positions: [10]int
		for digit := 0; digit < 10; digit += 1 { positions[digit] = -1 }
		for index := 0; index < length; index += 1 { positions[digits[index]] = index }
		satisfied := true
		for login in LOGINS {
			first := login / 100
			second := (login / 10) % 10
			third := login % 10
			if !(positions[first] < positions[second] && positions[second] < positions[third]) { satisfied = false; break }
		}
		if satisfied {
			passcode := i64(0)
			for index := 0; index < length; index += 1 { passcode = passcode * 10 + i64(digits[index]) }
			return passcode
		}
		if !next_permutation(&digits, length) { break }
	}
	return -1
}
