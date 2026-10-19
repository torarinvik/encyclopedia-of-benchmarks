package floatmm

import "core:c"

SIDE :: 40
MAX_PASSES :: i64(40)
MAX_OUTPUT_BYTES :: 14 * SIDE

rounded_add :: #force_no_inline proc "contextless" (left, right: f32) -> f32 { return left + right }
rounded_mul :: #force_no_inline proc "contextless" (left, right: f32) -> f32 { return left * right }
rounded_div :: #force_no_inline proc "contextless" (left, right: f32) -> f32 { return left / right }

next_random :: proc(seed: ^u32) -> u32 {
	seed^ = (seed^ * 1309 + 13849) & 65535
	return seed^
}

compute_diagonal_cell :: proc(selected: int) -> f32 {
	left: [SIDE * SIDE]f32
	right: [SIDE * SIDE]f32
	result: [SIDE * SIDE]f32
	seed := u32(74755)
	for row := 0; row < SIDE; row += 1 {
		for column := 0; column < SIDE; column += 1 {
			temp := next_random(&seed)
			remainder := i32(temp - (temp / 120) * 120)
			left[row * SIDE + column] = rounded_div(f32(remainder - 60), 3.0)
		}
	}
	for row := 0; row < SIDE; row += 1 {
		for column := 0; column < SIDE; column += 1 {
			temp := next_random(&seed)
			remainder := i32(temp - (temp / 120) * 120)
			right[row * SIDE + column] = rounded_div(f32(remainder - 60), 3.0)
		}
	}
	for row := 0; row < SIDE; row += 1 {
		for column := 0; column < SIDE; column += 1 {
			total: f32 = 0
			for inner := 0; inner < SIDE; inner += 1 {
				product := rounded_mul(left[row * SIDE + inner], right[inner * SIDE + column])
				total = rounded_add(total, product)
			}
			result[row * SIDE + column] = total
		}
	}
	return result[selected * SIDE + selected]
}

write_unsigned :: proc(value: u64, output: [^]u8, offset: int) -> int {
	reversed: [24]u8
	count := 0
	remaining := value
	for {
		reversed[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for index := 0; index < count; index += 1 {
		output[offset + index] = reversed[count - index - 1]
	}
	return count
}

write_fixed_six :: proc(value: f32, output: [^]u8, offset: int) -> int {
	bits := transmute(u32)value
	exponent_bits := (bits >> 23) & 255
	fraction_bits := bits & 0x7fffff
	significand := u64(fraction_bits)
	if exponent_bits != 0 do significand = u64((1 << 23) | fraction_bits)
	shift := -149
	if exponent_bits != 0 do shift = int(exponent_bits) - 150
	numerator := significand * 1_000_000
	micros: u64
	if shift >= 0 {
		micros = numerator << u32(shift)
	} else {
		denominator_shift := u32(-shift)
		if denominator_shift >= 64 {
			micros = 0
		} else {
			micros = numerator >> denominator_shift
			remainder := numerator & ((u64(1) << denominator_shift) - 1)
			halfway := u64(1) << (denominator_shift - 1)
			if remainder > halfway || (remainder == halfway && (micros & 1) != 0) do micros += 1
		}
	}
	position := offset
	if (bits >> 31) != 0 {
		output[position] = u8('-')
		position += 1
	}
	position += write_unsigned(micros / 1_000_000, output, position)
	output[position] = u8('.')
	position += 1
	fractional := u32(micros % 1_000_000)
	place := u32(100_000)
	for place > 0 {
		output[position] = u8(48 + (fractional / place) % 10)
		position += 1
		place /= 10
	}
	output[position] = u8('\n')
	return position + 1 - offset
}

@(export, link_name="floatmm")
floatmm :: proc "c" (passes: i64, output: [^]u8, output_capacity: c.size_t) -> i64 {
	if passes < 0 || passes > MAX_PASSES do return -1
	if passes == 0 do return 0
	if output == nil do return -2
	formatted: [MAX_OUTPUT_BYTES]u8
	required := 0
	for run := i64(0); run < passes; run += 1 {
		diagonal := compute_diagonal_cell(int(run))
		required += write_fixed_six(diagonal, &formatted[0], required)
	}
	if output_capacity < c.size_t(required) do return -2
	for index := 0; index < required; index += 1 do output[index] = formatted[index]
	return i64(required)
}
