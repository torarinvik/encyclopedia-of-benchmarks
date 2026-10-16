module frequency_finder

@[export: 'frequency_finder']
pub fn frequency_finder(input &i64, length usize) i64 {
	etaoin := 'ETAOINSHRDLCUMWFGYPBVKJXQZ'
	if unsafe { input == nil } { if length == 0 { return 0 }; return -1 }
	if length > 1024 { return -1 }
	mut counts := [26]i64{}
	for i in 0 .. int(length) {
		mut b := input[i]
		if b < 0 || b > 127 { return -1 }
		if b >= 97 && b <= 122 { b -= 32 }
		if b >= 65 && b <= 90 { counts[int(b - 65)]++ }
	}
	mut order := []int{len: 26}
	for i in 0 .. 26 { order[i] = i }
	for i in 1 .. 26 {
		key := order[i]; mut j := i; mut kr := 0
		for etaoin[kr] != u8(65 + key) { kr++ }
		for j > 0 {
			p := order[j - 1]; mut pr := 0
			for etaoin[pr] != u8(65 + p) { pr++ }
			if counts[p] > counts[key] || (counts[p] == counts[key] && pr > kr) { break }
			order[j] = p; j--
		}
		order[j] = key
	}
	mut score := i64(0)
	for i in 0 .. 6 {
		for j in 0 .. 6 { if u8(65 + order[i]) == etaoin[j] { score++; break } }
		for j in 20 .. 26 { if u8(65 + order[20 + i]) == etaoin[j] { score++; break } }
	}
	return score
}
