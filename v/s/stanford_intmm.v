module stanford_intmm

const row_size = 40
const cell_count = row_size * row_size
const max_passes = 10

fn decimal_width(value i32) int {
	mut magnitude := i64(value)
	if magnitude < 0 { magnitude = -magnitude }
	mut width := 0
	if value < 0 { width = 1 }
	for {
		width++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	return width
}

fn write_decimal(value i32, mut output &u8, mut position int) int {
	mut magnitude := i64(value)
	if magnitude < 0 {
		unsafe { output[position] = u8(`-`) }
		position++
		magnitude = -magnitude
	}
	mut reversed := [10]u8{}
	mut count := 0
	for {
		reversed[count] = u8(48 + magnitude % 10)
		count++
		magnitude /= 10
		if magnitude == 0 { break }
	}
	for count > 0 {
		count--
		unsafe { output[position] = reversed[count] }
		position++
	}
	return position
}

@[export: 'stanford_intmm']
pub fn stanford_intmm(pass_count i64, mut output &u8, output_capacity usize) i64 {
	if pass_count < 1 || pass_count > i64(max_passes) {
		return -1
	}

	mut a := [cell_count]i32{}
	mut b := [cell_count]i32{}
	mut product := [cell_count]i32{}
	mut diagonal := [max_passes]i32{}
	for pass in 0 .. int(pass_count) {
		mut seed := i64(74755)
		for index in 0 .. cell_count {
			seed = (seed * 1309 + 13849) & 65535
			a[index] = i32(seed % 120 - 60)
		}
		for index in 0 .. cell_count {
			seed = (seed * 1309 + 13849) & 65535
			b[index] = i32(seed % 120 - 60)
		}

		for row in 0 .. row_size {
			for column in 0 .. row_size {
				mut sum := i32(0)
				for inner in 0 .. row_size {
					sum += a[row * row_size + inner] * b[inner * row_size + column]
				}
				product[row * row_size + column] = sum
			}
		}
		diagonal[pass] = product[pass * row_size + pass]
	}

	mut required := 0
	for pass in 0 .. int(pass_count) {
		required += decimal_width(diagonal[pass]) + 1
	}
	if output == nil || output_capacity < required {
		return -2
	}

	mut position := 0
	for pass in 0 .. int(pass_count) {
		position = write_decimal(diagonal[pass], mut output, position)
		unsafe { output[position] = 10 }
		position++
	}
	return i64(position)
}
