module main_lorentz_tandem_repetitions

const ml_n = 24
const ml_max_repetitions = ml_n * ml_n / 4
const ml_input_max = ml_n + 1
const ml_z_max = 2 * ml_n + 1

fn ml_min(a int, b int) int { return if a < b { a } else { b } }
fn ml_max(a int, b int) int { return if a > b { a } else { b } }

fn ml_z_values(text [ml_z_max]i64, length int) [ml_z_max]int {
	mut z := [ml_z_max]int{}
	mut left := 0
	mut right := 0
	mut has_box := false
	for i in 1 .. length {
		if has_box && i <= right { z[i] = ml_min(right - i + 1, z[i - left]) }
		for i + z[i] < length && text[z[i]] == text[i + z[i]] { z[i]++ }
		if !has_box || i + z[i] - 1 > right { left, right, has_box = i, i + z[i] - 1, true }
	}
	return z
}

fn ml_z_at(z [ml_z_max]int, length int, index int) int {
	return if index < length { z[index] } else { 0 }
}

fn ml_divide(symbols [ml_n]i64, offset int, length int,
	mut marked [ml_n * (ml_n + 1)]bool) {
	if length <= 1 { return }
	left_size := length / 2
	right_size := length - left_size
	middle := offset + left_size
	mut buffer := [ml_z_max]i64{}
	mut before, after := [ml_n]int{}, [ml_n]int{}
	ml_divide(symbols, offset, left_size, mut marked)
	ml_divide(symbols, middle, right_size, mut marked)

	for i in 0 .. left_size { buffer[i] = symbols[middle - 1 - i] }
	z := ml_z_values(buffer, left_size)
	for center in 0 .. left_size { before[center] = ml_z_at(z, left_size, left_size - center) }

	mut used := 0
	for i in 0 .. right_size { buffer[used] = symbols[middle + i]; used++ }
	buffer[used] = -1
	used++
	for i in 0 .. left_size { buffer[used] = symbols[offset + i]; used++ }
	z = ml_z_values(buffer, used)
	for center in 0 .. left_size { after[center] = ml_z_at(z, used, right_size + 1 + center) }

	for i in 0 .. left_size { buffer[i] = symbols[middle - 1 - i] }
	used = left_size
	buffer[used] = -1
	used++
	for i in 0 .. right_size { buffer[used] = symbols[offset + length - 1 - i]; used++ }
	z = ml_z_values(buffer, used)
	for d in 0 .. right_size { before[left_size + d] = ml_z_at(z, used, left_size + 1 + right_size - 1 - d) }

	for i in 0 .. right_size { buffer[i] = symbols[middle + i] }
	z = ml_z_values(buffer, right_size)
	for d in 0 .. right_size { after[left_size + d] = ml_z_at(z, right_size, d + 1) }

	for center in 0 .. length {
		left_biased := center < left_size
		half := if left_biased { left_size - center } else { center - left_size + 1 }
		if before[center] + after[center] < half { continue }
		low := ml_max(1, half - after[center])
		high := ml_min(half, before[center])
		for first_half := low; first_half <= high; first_half++ {
			if left_biased && first_half == half { continue }
			start := if left_biased { center - first_half } else { center - half - first_half + 1 }
			marked[(offset + start) * (ml_n + 1) + half] = true
		}
	}
}

fn ml_store(mut output &u8, offset int, value i64) {
	bits := u64(value)
	unsafe { for byte in 0 .. 8 { output[offset + byte] = u8((bits >> (8 * byte)) & 255) } }
}

@[export: 'main_lorentz_tandem_repetitions']
pub fn main_lorentz_tandem_repetitions(input &i64, length usize,
	mut output &u8, capacity usize) i64 {
	unsafe {
		if input == nil || length < 1 || length > ml_input_max { return -1 }
		n_raw := input
		if n_raw < 0 || n_raw > ml_n || length != usize(n_raw + 1) { return -1 }
		n := int(n_raw)
		mut symbols := [ml_n]i64{}
		for i in 0 .. n { symbols[i] = input[i + 1]; if symbols[i] < 0 || symbols[i] > 255 { return -1 } }
		mut marked := [ml_n * (ml_n + 1)]bool{}
		ml_divide(symbols, 0, n, mut marked)
		mut codes := [ml_max_repetitions]i64{}
		mut count := 0
		for start := 0; start < n; start++ {
			for half := 1; half <= n / 2; half++ {
				if start + 2 * half <= n && marked[start * (ml_n + 1) + half] { codes[count] = i64(start * 32 + half); count++ }
			}
		}
		required := 8 * (count + 1)
		if output == nil || capacity < usize(required) { return -2 }
		ml_store(mut output, 0, i64(count))
		for i in 0 .. count { ml_store(mut output, 8 * (i + 1), codes[i]) }
		return i64(required)
	}
}
