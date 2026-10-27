module fm_index_display

const max_text = 32
const max_input = 36

fn suffix_less(text []i64, a0 int, b0 int) bool {
	mut a := a0
	mut b := b0
	for a < text.len && b < text.len {
		if text[a] != text[b] { return text[a] < text[b] }
		a++
		b++
	}
	return a == text.len && b != text.len
}

@[export: 'fm_index_display']
pub fn fm_index_display(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 5 || length > max_input { return -1 }
		n0 := input[0]
		if n0 < 1 || n0 > max_text || length != usize(n0 + 4) { return -1 }
		n := int(n0)
		left0 := input[n + 1]
		right0 := input[n + 2]
		stride0 := input[n + 3]
		if left0 < 0 || right0 < left0 || right0 >= n0 || stride0 < 1 || stride0 > n0 { return -1 }
		left := int(left0)
		right := int(right0)
		stride := int(stride0)
		size := n + 1
		mut text := []i64{len: size, init: 0}
		for i in 0 .. n {
			x := input[i + 1]
			if x < 1 || x > 4 { return -1 }
			text[i] = x
		}
		text[n] = 0
		mut sa := []int{len: size, init: 0}
		for i in 0 .. size { sa[i] = i }
		for i in 1 .. size {
			key := sa[i]
			mut j := i
			for j > 0 && suffix_less(text, key, sa[j - 1]) { sa[j] = sa[j - 1]; j-- }
			sa[j] = key
		}
		mut isa := []int{len: size, init: 0}
		mut bwt := []int{len: size, init: 0}
		mut freq := []int{len: 5, init: 0}
		for row in 0 .. size {
			pos := sa[row]
			isa[pos] = row
			bwt[row] = int(text[(pos + size - 1) % size])
			freq[bwt[row]]++
		}
		mut first := []int{len: 5, init: 0}
		mut total := 0
		for c in 0 .. 5 { first[c] = total; total += freq[c] }
		mut seen := []int{len: 5, init: 0}
		mut lf := []int{len: size, init: 0}
		for row in 0 .. size { sym := bwt[row]; lf[row] = first[sym] + seen[sym]; seen[sym]++ }
		mut sampled_isa := []int{len: size, init: 0}
		mut sampled := []bool{len: size, init: false}
		mut pos := 0
		for pos < n { if (pos + 1) % stride == 0 { sampled[pos] = true; sampled_isa[pos] = isa[pos] }; pos++ }
		sampled[n] = true
		sampled_isa[n] = isa[n]
		mut sample := ((right + 1) / stride + 1) * stride - 1
		if sample > n { sample = n }
		if !sampled[sample] { return -1 }
		mut row := sampled_isa[sample]
		mut current := sample
		for current > right + 1 { row = lf[row]; current-- }
		mut reversed := []u8{len: max_text, init: 0}
		mut count := 0
		for current > left { reversed[count] = u8(bwt[row]); count++; row = lf[row]; current-- }
		if count != right - left + 1 { return -1 }
		if output == nil || capacity < usize(count) { return -2 }
		for i in 0 .. count { output[i] = reversed[count - 1 - i] }
		return i64(count)
	}
}
