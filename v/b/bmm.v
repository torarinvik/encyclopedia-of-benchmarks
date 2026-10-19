module versabench_bmm

// Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source.

const max_size = 128
const source_size = 1024
const max_cells = max_size * max_size
const max_output_bytes = 29

fn next_random(mut state u32) u32 {
	state = u32((u64(state) * 1_664_525 + 1_013_904_223) & 0xffff_ffff)
	return (state >> 16) & u32(0x7fff)
}

fn append_unsigned(value_input u32, mut staged [max_output_bytes]u8, used_input int) int {
	mut value := value_input
	mut used := used_input
	mut reverse := [10]u8{}
	mut count := 0
	for {
		reverse[count] = u8(48 + value % u32(10))
		count++
		value /= u32(10)
		if value == 0 { break }
	}
	for count > 0 {
		count--
		staged[used] = reverse[count]
		used++
	}
	return used
}

@[export: 'versabench_bmm']
pub fn versabench_bmm(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if input == nil || length != 2 { return -1 }
		if input[0] < 1 || input[0] > max_size || input[1] < 1 ||
			input[1] > input[0] || input[0] % input[1] != 0 { return -1 }
		size := int(input[0])
		block := int(input[1])

		mut a := [max_cells]f32{}
		mut b := [max_cells]f32{}
		mut matrix_c := [max_cells]f32{}
		mut seed := u32(1)
		for i in 0 .. size {
			for j in 0 .. source_size {
				random_a := next_random(mut seed)
				random_b := next_random(mut seed)
				if j < size {
					shift_a := ((j & 31) + 32 - (i & 31)) & 31
					shift_b := (i + j) & 31
					a[i * size + j] = f32((random_a >> shift_a) & u32(15))
					b[i * size + j] = f32((random_b << shift_b) & u32(15))
				}
			}
		}

		for outer_i := 0; outer_i < size; outer_i += block {
			for outer_j := 0; outer_j < size; outer_j += block {
				for outer_k := 0; outer_k < size; outer_k += block {
					for i in outer_i .. outer_i + block {
						for j in outer_j .. outer_j + block {
							cell := i * size + j
							for k in outer_k .. outer_k + block {
								matrix_c[cell] += a[i * size + k] * b[k * size + j]
							}
						}
					}
				}
			}
		}

		mut total := f32(0)
		for outer_i := 0; outer_i < size; outer_i += block {
			for outer_j := 0; outer_j < size; outer_j += block {
				mut subtotal := f32(0)
				for i in outer_i .. outer_i + block {
					for j in outer_j .. outer_j + block {
						subtotal += matrix_c[i * size + j]
					}
				}
				total += subtotal
			}
		}

		mut staged := [max_output_bytes]u8{}
		mut used := 0
		prefix := 'final sum = '.bytes()
		for i in 0 .. 12 { staged[i] = prefix[i] }
		used = 12
		used = append_unsigned(u32(total), mut staged, used)
		suffix := '.000000\n'.bytes()
		for i in 0 .. 8 { staged[used + i] = suffix[i] }
		used += 8
		if output == nil || output_capacity < usize(used) { return -2 }
		for i in 0 .. used { output[i] = staged[i] }
		return i64(used)
	}
}
