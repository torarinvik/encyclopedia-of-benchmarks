module suffix_array_sais

const max_text_length = 32
const max_input_length = 34
const max_alphabet = 256

fn induce(symbols []int, upper int, is_s []bool, sum_s []int, sum_l []int,
          ordered_lms []int) []int {
	 n := symbols.len
	 mut suffixes := []int{len: n, init: -1}
	 mut bucket := sum_s.clone()
	 for position in ordered_lms {
		 symbol := symbols[position]
		 suffixes[bucket[symbol]] = position
		 bucket[symbol]++
	 }
	 bucket = sum_l.clone()
	 for i in 0 .. n {
		 position := suffixes[i]
		 if position > 0 && !is_s[position - 1] {
			 symbol := symbols[position - 1]
			 suffixes[bucket[symbol]] = position - 1
			 bucket[symbol]++
		 }
	 }
	 bucket = sum_l.clone()
	 for i := n - 1; i >= 0; i-- {
		 position := suffixes[i]
		 if position > 0 && is_s[position - 1] {
			 symbol := symbols[position - 1] + 1
			 bucket[symbol]--
			 suffixes[bucket[symbol]] = position - 1
		 }
	 }
	 _ = upper
	 return suffixes
}

fn same_lms_substring(symbols []int, is_s []bool, lms_map []int,
                      left int, right int) bool {
	 if left == right { return true }
	 for offset in 0 .. symbols.len {
		 a := left + offset
		 b := right + offset
		 if a >= symbols.len || b >= symbols.len || symbols[a] != symbols[b] || is_s[a] != is_s[b] {
			 return false
		 }
		 a_lms := offset > 0 && lms_map[a] >= 0
		 b_lms := offset > 0 && lms_map[b] >= 0
		 if a_lms || b_lms { return a_lms && b_lms }
	 }
	 return false
}

fn sais(symbols []int, upper int) []int {
	 n := symbols.len
	 if n == 0 { return []int{} }
	 if n <= 2 {
		 mut suffixes := []int{len: n, init: 0}
		 for i in 0 .. n { suffixes[i] = i }
		 if n == 2 && symbols[0] >= symbols[1] { suffixes[0] = 1; suffixes[1] = 0 }
		 return suffixes
	 }
	 mut is_s := []bool{len: n, init: false}
	 is_s[n - 1] = true
	 for i := n - 2; i >= 0; i-- {
		 is_s[i] = symbols[i] < symbols[i + 1] || (symbols[i] == symbols[i + 1] && is_s[i + 1])
	 }
	 mut lms_map := []int{len: n + 1, init: -1}
	 mut lms := []int{}
	 for i in 1 .. n {
		 if !is_s[i - 1] && is_s[i] { lms_map[i] = lms.len; lms << i }
	 }
	 mut sum_s := []int{len: max_alphabet + 2, init: 0}
	 mut sum_l := []int{len: max_alphabet + 2, init: 0}
	 for i in 0 .. n {
		 symbol := symbols[i]
		 if is_s[i] { sum_l[symbol + 1]++ } else { sum_s[symbol]++ }
	 }
	 for symbol in 0 .. upper + 1 {
		 sum_s[symbol] += sum_l[symbol]
		 sum_l[symbol + 1] += sum_s[symbol]
	 }
	 mut suffixes := induce(symbols, upper, is_s, sum_s, sum_l, lms)
	 mut sorted_lms := []int{}
	 for position in suffixes {
		 if position >= 0 && lms_map[position] >= 0 { sorted_lms << position }
	 }
	 mut reduced := []int{len: lms.len, init: 0}
	 mut reduced_upper := 0
	 for i in 0 .. sorted_lms.len {
		 if i > 0 && !same_lms_substring(symbols, is_s, lms_map, sorted_lms[i - 1], sorted_lms[i]) {
			 reduced_upper++
		 }
		 reduced[lms_map[sorted_lms[i]]] = reduced_upper
	 }
	 mut reduced_order := []int{}
	 if reduced_upper + 1 == reduced.len {
		 reduced_order = []int{len: reduced.len, init: 0}
		 for i, name in reduced { reduced_order[name] = i }
	 } else {
		 reduced_order = sais(reduced, reduced_upper)
	 }
	 mut ordered_lms := []int{len: reduced_order.len, init: 0}
	 for i, index in reduced_order { ordered_lms[i] = lms[index] }
	 return induce(symbols, upper, is_s, sum_s, sum_l, ordered_lms)
}

@[export: 'suffix_array_sais']
pub fn suffix_array_sais(values &i64, length usize, mut output &u8, capacity usize) i64 {
	 unsafe {
		 if values == nil || length < 1 || length > max_input_length { return -1 }
		 count_value := values[0]
		 if count_value < 0 || count_value > max_text_length { return -1 }
		 count := int(count_value)
		 if length != usize(count + 1) { return -1 }
		 mut symbols := []int{len: count + 1, init: 0}
		 for i in 0 .. count {
			 if values[i + 1] < 0 || values[i + 1] > 255 { return -1 }
			 symbols[i] = int(values[i + 1]) + 1
		 }
		 output_bytes := count * 8
		 if output == nil || capacity < usize(output_bytes) { return -2 }
		 symbols[count] = 0
		 suffixes := sais(symbols, max_alphabet)
		 mut out := 0
		 for position in suffixes {
			 if position == count { continue }
			 bits := u64(position)
			 for byte in 0 .. 8 { output[out * 8 + byte] = u8((bits >> (byte * 8)) & 255) }
			 out++
		 }
		 return i64(output_bytes)
	 }
}
