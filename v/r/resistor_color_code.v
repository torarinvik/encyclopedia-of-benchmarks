module main

const max_text_length = 41
const max_parseable_length = 43

fn color_code(values &i64, start int, finish int) int {
	names := ['Black', 'Brown', 'Red', 'Orange', 'Yellow', 'Green', 'Blue', 'Violet', 'Grey', 'White', 'Gold', 'Silver']
	for color, name in names {
		if name.len != finish - start { continue }
		mut same := true
		for i in 0 .. name.len { if values[start + i + 1] != i64(name[i]) { same = false } }
		if same { return color }
	}
	return -1
}

fn append_text(mut output []u8, text string) {
	for byte in text.bytes() { output << byte }
}

fn append_uint(mut output []u8, value u64) {
	append_text(mut output, value.str())
}

fn tolerance_allowed(color int) bool {
	return (color >= 1 && color <= 8) || color == 10 || color == 11
}

@[export: 'resistor_color_code']
pub fn resistor_color_code(values &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if values == nil || length < 2 || length > max_parseable_length { return -1 }
		text_length := values[0]
		if text_length < 1 || text_length > max_text_length || length != usize(text_length + 1) { return -1 }
		for i in 0 .. int(text_length) { if values[i + 1] < 0 || values[i + 1] > 127 { return -1 } }

		mut colors := []int{len: 6, init: 0}
		mut color_count := 0
		mut start := 0
		for i in 0 .. int(text_length) + 1 {
			if i == int(text_length) || values[i + 1] == `,` {
				if color_count == 6 || i == start { return -1 }
				color := color_code(values, start, i)
				if color < 0 { return -1 }
				colors[color_count] = color
				color_count++
				start = i + 1
			}
		}
		if color_count < 3 || color_count > 6 { return -1 }

		significant_count := if color_count <= 4 { 2 } else { 3 }
		mut significant := u64(0)
		for i in 0 .. significant_count {
			if colors[i] > 9 { return -1 }
			significant = significant * 10 + u64(colors[i])
		}
		multiplier := colors[significant_count]
		tolerance_color := if color_count >= 4 { colors[significant_count + 1] } else { -1 }
		temperature_color := if color_count == 6 { colors[5] } else { -1 }
		if tolerance_color >= 0 && !tolerance_allowed(tolerance_color) { return -1 }
		if temperature_color > 8 { return -1 }

		mut answer := []u8{cap: 64}
		if multiplier <= 9 {
			mut resistance := significant
			for _ in 0 .. multiplier { resistance *= 10 }
			append_uint(mut answer, resistance)
		} else if multiplier == 10 {
			append_uint(mut answer, significant / 10)
			answer << u8(`.`)
			answer << u8(48 + int(significant % 10))
		} else {
			whole := significant / 100
			fraction := int(significant % 100)
			append_uint(mut answer, whole)
			answer << u8(`.`)
			if fraction == 0 { answer << u8(`0`) }
			else if fraction % 10 == 0 { answer << u8(`0` + fraction / 10) }
			else { answer << u8(`0` + fraction / 10); answer << u8(`0` + fraction % 10) }
		}
		answer << u8(0xce); answer << u8(0xa9); answer << u8(` `); answer << u8(0xc2); answer << u8(0xb1)
		tolerance_text := ['','1','2','0.05','0.02','0.5','0.25','0.1','0.01','','5','10']
		append_text(mut answer, if tolerance_color < 0 { '20' } else { tolerance_text[tolerance_color] })
		append_text(mut answer, '% ')
		if temperature_color >= 0 {
			temperature_values := [250, 100, 50, 15, 25, 20, 10, 5, 1]
			append_uint(mut answer, u64(temperature_values[temperature_color]))
			append_text(mut answer, ' ppm/K')
		}
		if capacity < usize(answer.len) || (answer.len > 0 && output == nil) { return -2 }
		for i in 0 .. answer.len { output[i] = answer[i] }
		return i64(answer.len)
	}
}
