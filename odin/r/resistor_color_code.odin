package resistor_color_code

MAX_TEXT_LENGTH :: i64(41)
MAX_PARSEABLE_LENGTH :: int(43)
COLOR_NAMES :: [12]string{"Black", "Brown", "Red", "Orange", "Yellow", "Green", "Blue", "Violet", "Grey", "White", "Gold", "Silver"}
TOLERANCE_TEXT :: [12]string{"", "1", "2", "0.05", "0.02", "0.5", "0.25", "0.1", "0.01", "", "5", "10"}
TEMPERATURE_VALUES :: [9]u64{250, 100, 50, 15, 25, 20, 10, 5, 1}

color_code :: proc(values: [^]i64, start, finish: int) -> int {
	for color in 0..<12 {
		name := COLOR_NAMES[color]
		if len(name) != finish - start do continue
		same := true
		for i in 0..<len(name) { if values[start + i + 1] != i64(name[i]) do same = false }
		if same do return color
	}
	return -1
}

append_byte :: proc(buffer: ^[64]u8, length: ^int, byte: u8) {
	buffer[length^] = byte
	length^ += 1
}

append_text :: proc(buffer: ^[64]u8, length: ^int, text: string) {
	for i in 0..<len(text) { append_byte(buffer, length, text[i]) }
}

append_uint :: proc(buffer: ^[64]u8, length: ^int, value: u64) {
	var digits: [24]u8
	count := 0
	remaining := value
	for {
		digits[count] = u8('0' + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		append_byte(buffer, length, digits[count])
	}
}

@(export)
resistor_color_code :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length < 2 || length > c.size_t(MAX_PARSEABLE_LENGTH) do return -1
	text_length := values[0]
	if text_length < 1 || text_length > MAX_TEXT_LENGTH || length != c.size_t(text_length + 1) do return -1
	for i in 0..<int(text_length) { if values[i + 1] < 0 || values[i + 1] > 127 do return -1 }

	colors: [6]int
	color_count, start := 0, 0
	for i in 0..<(int(text_length) + 1) {
		if i == int(text_length) || values[i + 1] == i64(',') {
			if color_count == 6 || i == start do return -1
			color := color_code(values, start, i)
			if color < 0 do return -1
			colors[color_count] = color
			color_count += 1
			start = i + 1
		}
	}
	if color_count < 3 || color_count > 6 do return -1

	significant_count := 2
	if color_count > 4 do significant_count = 3
	significant: u64 = 0
	for i in 0..<significant_count {
		if colors[i] > 9 do return -1
		significant = significant * 10 + u64(colors[i])
	}
	multiplier := colors[significant_count]
	tolerance_color := -1
	if color_count >= 4 do tolerance_color = colors[significant_count + 1]
	temperature_color := -1
	if color_count == 6 do temperature_color = colors[5]
	if tolerance_color >= 0 && !((tolerance_color >= 1 && tolerance_color <= 8) || tolerance_color == 10 || tolerance_color == 11) do return -1
	if temperature_color > 8 do return -1

	buffer: [64]u8
	out_length := 0
	if multiplier <= 9 {
		resistance := significant
		for _ in 0..<multiplier { resistance *= 10 }
		append_uint(&buffer, &out_length, resistance)
	} else if multiplier == 10 {
		append_uint(&buffer, &out_length, significant / 10)
		append_byte(&buffer, &out_length, u8('.'))
		append_byte(&buffer, &out_length, u8('0' + significant % 10))
	} else {
		whole, fraction := significant / 100, significant % 100
		append_uint(&buffer, &out_length, whole)
		append_byte(&buffer, &out_length, u8('.'))
		if fraction == 0 do append_byte(&buffer, &out_length, u8('0'))
		else if fraction % 10 == 0 do append_byte(&buffer, &out_length, u8('0' + fraction / 10))
		else {
			append_byte(&buffer, &out_length, u8('0' + fraction / 10))
			append_byte(&buffer, &out_length, u8('0' + fraction % 10))
		}
	}
	append_byte(&buffer, &out_length, 0xce); append_byte(&buffer, &out_length, 0xa9)
	append_byte(&buffer, &out_length, u8(' ')); append_byte(&buffer, &out_length, 0xc2); append_byte(&buffer, &out_length, 0xb1)
	if tolerance_color < 0 do append_text(&buffer, &out_length, "20") else append_text(&buffer, &out_length, TOLERANCE_TEXT[tolerance_color])
	append_text(&buffer, &out_length, "% ")
	if temperature_color >= 0 {
		append_uint(&buffer, &out_length, TEMPERATURE_VALUES[temperature_color])
		append_text(&buffer, &out_length, " ppm/K")
	}
	if capacity < c.size_t(out_length) || (output == nil && out_length > 0) do return -2
	for i in 0..<out_length { output[i] = buffer[i] }
	return i64(out_length)
}
