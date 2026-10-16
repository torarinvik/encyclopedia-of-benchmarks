module transposition_cipher

const max_text = 256
const max_input = 259

@[export: 'transposition_cipher']
pub fn transposition_cipher(input &i64, length usize, output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length < 6 || length > max_input { return -1 }
	mode := unsafe { input[0] }
	key64 := unsafe { input[1] }
	n64 := unsafe { input[2] }
	if (mode != 0 && mode != 1) || n64 < 3 || n64 > max_text || key64 < 2 || key64 >= n64 { return -1 }
	n := int(n64)
	key := int(key64)
	if length != usize(3 + n) { return -1 }
	for i := 0; i < n; i++ {
		value := unsafe { input[3 + i] }
		if value < 0 || value > 127 { return -1 }
	}
	if unsafe { output == nil } || output_capacity < usize(n) { return -2 }
	mut transformed := [max_text]u8{}
	if mode == 0 {
		mut written := 0
		for column := 0; column < key; column++ {
			mut index := column
			for index < n {
				transformed[written] = u8(unsafe { input[3 + index] })
				written++
				index += key
			}
		}
	} else {
		columns := (n + key - 1) / key
		shaded := columns * key - n
		final_column_rows := key - shaded
		mut offsets := [max_text]int{}
		mut seen := [max_text]int{}
		mut total := 0
		for column := 0; column < columns; column++ {
			offsets[column] = total
			if column + 1 == columns { total += final_column_rows } else { total += key }
		}
		mut row := 0
		mut column := 0
		for i := 0; i < n; i++ {
			transformed[offsets[column] + seen[column]] = u8(unsafe { input[3 + i] })
			seen[column]++
			column++
			if column == columns || (column == columns - 1 && row >= final_column_rows) {
				column = 0
				row++
			}
		}
	}
	unsafe {
		for i := 0; i < n; i++ { output[i] = transformed[i] }
	}
	return i64(n)
}
