package fm_index_display
import "core:c"

MAX_TEXT :: 32
MAX_INPUT :: 36
ALPHABET :: 5

suffix_less :: proc(text: [^]i64, n, a0, b0: int) -> bool {
	a, b := a0, b0
	for a < n && b < n {
		if text[a] != text[b] { return text[a] < text[b] }
		a += 1
		b += 1
	}
	return a == n && b != n
}

@(export)
fm_index_display :: proc "c" (input: [^]i64, length: c.size_t,
		output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 5 || length > MAX_INPUT do return -1
	n64 := input[0]
	if n64 < 1 || n64 > MAX_TEXT || length != c.size_t(n64 + 4) do return -1
	n := int(n64)
	left64, right64, stride64 := input[n+1], input[n+2], input[n+3]
	if left64 < 0 || right64 < left64 || right64 >= n64 || stride64 < 1 || stride64 > n64 do return -1
	left, right, stride := int(left64), int(right64), int(stride64)
	size := n + 1
	text: [MAX_TEXT+1]i64
	for i := 0; i < n; i += 1 {
		if input[i+1] < 1 || input[i+1] > 4 do return -1
		text[i] = input[i+1]
	}
	text[n] = 0
	sa: [MAX_TEXT+1]int
	for i := 0; i < size; i += 1 { sa[i] = i }
	for i := 1; i < size; i += 1 {
		key := sa[i]
		j := i
		for j > 0 && suffix_less(&text[0], size, key, sa[j-1]) { sa[j] = sa[j-1]; j -= 1 }
		sa[j] = key
	}
	isa: [MAX_TEXT+1]int
	bwt: [MAX_TEXT+1]int
	freq: [ALPHABET]int
	for row := 0; row < size; row += 1 {
		pos := sa[row]
		isa[pos] = row
		bwt[row] = int(text[(pos+size-1)%size])
		freq[bwt[row]] += 1
	}
	first: [ALPHABET]int
	sum := 0
	for cidx := 0; cidx < ALPHABET; cidx += 1 { first[cidx] = sum; sum += freq[cidx] }
	seen: [ALPHABET]int
	lf: [MAX_TEXT+1]int
	for row := 0; row < size; row += 1 { sym := bwt[row]; lf[row] = first[sym]+seen[sym]; seen[sym] += 1 }
	sampled_isa: [MAX_TEXT+1]int
	sampled: [MAX_TEXT+1]bool
	for pos := 0; pos < n; pos += 1 { if (pos+1)%stride == 0 { sampled[pos] = true; sampled_isa[pos] = isa[pos] } }
	sampled[n] = true
	sampled_isa[n] = isa[n]
	sample := ((right+1)/stride+1)*stride-1
	if sample > n { sample = n }
	if !sampled[sample] do return -1
	row, current := sampled_isa[sample], sample
	for current > right+1 { row = lf[row]; current -= 1 }
	reversed: [MAX_TEXT]u8
	count := 0
	for current > left { reversed[count] = u8(bwt[row]); count += 1; row = lf[row]; current -= 1 }
	if count != right-left+1 do return -1
	if output == nil || capacity < c.size_t(count) do return -2
	for i := 0; i < count; i += 1 { output[i] = reversed[count-1-i] }
	return i64(count)
}
