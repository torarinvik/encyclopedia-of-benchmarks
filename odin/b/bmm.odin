package versabench_bmm

import "core:c"

// Modified bounded-profile derivative; carry benchmarks/b/bmm/LICENSE with this source.

MAX_SIZE :: 128
SOURCE_SIZE :: 1024
MAX_CELLS :: MAX_SIZE * MAX_SIZE
MAX_OUTPUT_BYTES :: 29

next_random :: proc(state: ^u32) -> u32 {
	state^ = u32(u64(state^) * 1_664_525 + 1_013_904_223)
	return (state^ >> 16) & 0x7fff
}

append_unsigned :: proc(value_input: u32, staged: []u8, used_input: int) -> int {
	value := value_input
	used := used_input
	var reverse: [10]u8
	count := 0
	for {
		reverse[count] = u8('0') + u8(value % 10)
		count += 1
		value /= 10
		if value == 0 do break
	}
	for count > 0 {
		count -= 1
		staged[used] = reverse[count]
		used += 1
	}
	return used
}

@(export, link_name="versabench_bmm")
versabench_bmm :: proc "c" (input: [^]i64, length: c.size_t,
	output: [^]u8, output_capacity: c.size_t) -> i64 {
	if input == nil || length != 2 do return -1
	if input[0] < 1 || input[0] > MAX_SIZE || input[1] < 1 ||
		input[1] > input[0] || input[0] % input[1] != 0 do return -1
	size := int(input[0])
	block := int(input[1])

	var a: [MAX_CELLS]f32
	var b: [MAX_CELLS]f32
	var matrix_c: [MAX_CELLS]f32
	seed := u32(1)
	for i in 0..<size {
		for j in 0..<SOURCE_SIZE {
			random_a := next_random(&seed)
			random_b := next_random(&seed)
			if j < size {
				shift_a := ((j & 31) + 32 - (i & 31)) & 31
				shift_b := (i + j) & 31
				a[i*size+j] = f32((random_a >> u32(shift_a)) & 15)
				b[i*size+j] = f32((random_b << u32(shift_b)) & 15)
			}
		}
	}

	for outer_i := 0; outer_i < size; outer_i += block {
		for outer_j := 0; outer_j < size; outer_j += block {
			for outer_k := 0; outer_k < size; outer_k += block {
				for i in outer_i..<outer_i+block {
					for j in outer_j..<outer_j+block {
						cell := i*size + j
						for k in outer_k..<outer_k+block {
							matrix_c[cell] += a[i*size+k] * b[k*size+j]
						}
					}
				}
			}
		}
	}

	total := f32(0)
	for outer_i := 0; outer_i < size; outer_i += block {
		for outer_j := 0; outer_j < size; outer_j += block {
			subtotal := f32(0)
			for i in outer_i..<outer_i+block {
				for j in outer_j..<outer_j+block {
					subtotal += matrix_c[i*size+j]
				}
			}
			total += subtotal
		}
	}

	var staged: [MAX_OUTPUT_BYTES]u8
	used := 0
	prefix := "final sum = "
	for i in 0..<12 do staged[i] = prefix[i]
	used = 12
	used = append_unsigned(u32(total), staged[:], used)
	suffix := ".000000\n"
	for i in 0..<8 do staged[used+i] = suffix[i]
	used += 8
	if output == nil || output_capacity < c.size_t(used) do return -2
	for i in 0..<used do output[i] = staged[i]
	return i64(used)
}
