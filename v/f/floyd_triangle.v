module floyd_triangle

const max_rows = 90

@[export: 'floyd_triangle']
pub fn floyd_triangle(rows i64, output &u8, output_capacity usize) i64 {
	if rows < 0 || rows > max_rows { return -1 }
	count := usize(rows) * (usize(rows) + 1) / 2
	output_length := count * 2
	unsafe {
		if output_capacity < output_length || (output_length > 0 && output == nil) { return -2 }
		mut index := usize(0)
		mut number := u32(1)
		for row := usize(1); row <= usize(rows); row++ {
			for _ in 0 .. int(row) {
				output[index * 2] = u8(number & 0xff)
				output[index * 2 + 1] = u8((number >> 8) & 0xff)
				number++
				index++
			}
		}
	}
	return i64(output_length)
}
