module convert_number_to_words

const words = ['zero','one','two','three','four','five','six','seven','eight','nine','ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen','twenty','thirty','forty','fifty','sixty','seventy','eighty','ninety','quadrillion','trillion','billion','million','thousand','hundred','billiard','milliard','crore crore','lakh crore','crore','lakh','negative']

fn append_word(mut output &u8, length int, id int, separate bool) int {
	mut position := length
	if separate && position > 0 { unsafe { output[position] = ` ` }; position++ }
	text := words[id]
	for i in 0 .. text.len { unsafe { output[position + i] = text[i] } }
	return position + text.len
}
fn append_small(n u64, mut output &u8, length int) int {
	if n < 10 { return append_word(mut output, length, int(n), true) }
	if n < 20 { return append_word(mut output, length, int(n) + 10, true) }
	mut position := append_word(mut output, length, int(n / 10) + 18, true)
	if n % 10 != 0 { unsafe { output[position] = `-` }; position++; position = append_word(mut output, position, int(n % 10), false) }
	return position
}
fn scale_count(system int) int { return if system == 1 { 5 } else { 6 } }
fn scale_power(system int, index int) u64 {
	if system == 0 { return [6]u64{1_000_000_000_000_000,1_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index] }
	if system == 1 { return [5]u64{1_000_000_000_000_000,1_000_000_000,1_000_000,1_000,100}[index] }
	return [6]u64{100_000_000_000_000,1_000_000_000_000,10_000_000,100_000,1_000,100}[index]
}
fn scale_word(system int, index int) int {
	if system == 0 { return [6]int{28,29,30,31,32,33}[index] }
	if system == 1 { return [5]int{34,35,31,32,33}[index] }
	return [6]int{36,37,38,39,32,33}[index]
}
fn append_number(n_input u64, system int, mut output &u8, length int, depth int) int {
	if depth > 8 { return length }
	mut n := n_input
	mut position := length
	for i in 0 .. scale_count(system) {
		power := scale_power(system, i)
		group := n / power
		n %= power
		if group == 0 { continue }
		if group >= 100 { position = append_number(group, system, mut output, position, depth + 1) }
		else { position = append_small(group, mut output, position) }
		position = append_word(mut output, position, scale_word(system, i), true)
	}
	if n > 0 || position == length { position = append_small(n, mut output, position) }
	return position
}

@[export: 'convert_number_to_words']
pub fn convert_number_to_words(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		if input[1] < 0 || input[1] > 2 { return -1 }
		system := int(input[1]); number := input[0]
		mut limit := i64(9000000000000000000)
		if system == 0 { limit = 999999999999999999 }
		if number < -limit || number > limit { return -1 }
		magnitude := u64(if number < 0 { -number } else { number })
		mut temporary := [512]u8{}
		mut count := 0
		if number < 0 { count = append_word(mut temporary[0], count, 40, true) }
		count = append_number(magnitude, system, mut temporary[0], count, 0)
		if capacity < usize(count) || output == nil { return -2 }
		for i in 0 .. count { output[i] = temporary[i] }
		return i64(count)
	}
}
