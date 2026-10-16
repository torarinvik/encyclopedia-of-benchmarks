package frequency_finder

@(export)
frequency_finder :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
	etaoin := "ETAOINSHRDLCUMWFGYPBVKJXQZ"
	if input == nil { if length == 0 do return 0; return -1 }
	if length > 1024 do return -1
	counts: [26]i64 = {}
	for i in 0..<int(length) {
		b := input[i]
		if b < 0 || b > 127 do return -1
		if b >= 97 && b <= 122 do b -= 32
		if b >= 65 && b <= 90 do counts[int(b - 65)] += 1
	}
	order: [26]int
	for i in 0..<26 { order[i] = i }
	for i in 1..<26 {
		key := order[i]; j := i; kr := 0
		for etaoin[kr] != u8(65 + key) { kr += 1 }
		for j > 0 {
			p := order[j-1]; pr := 0
			for etaoin[pr] != u8(65 + p) { pr += 1 }
			if counts[p] > counts[key] || (counts[p] == counts[key] && pr > kr) do break
			order[j] = p; j -= 1
		}
		order[j] = key
	}
	score := i64(0)
	for i in 0..<6 {
		for j in 0..<6 { if u8(65 + order[i]) == etaoin[j] { score += 1; break } }
		for j in 20..<26 { if u8(65 + order[20+i]) == etaoin[j] { score += 1; break } }
	}
	return score
}
