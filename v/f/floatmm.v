module floatmm

import math

const side = 40
const max_passes = i64(40)
const max_output_bytes = 14 * side

@[noinline]
fn rounded_add(left f32, right f32) f32 { return left + right }
@[noinline]
fn rounded_mul(left f32, right f32) f32 { return left * right }
@[noinline]
fn rounded_div(left f32, right f32) f32 { return left / right }

fn next_random(mut seed u32) u32 {
	seed = (seed * 1309 + 13849) & 65535
	return seed
}

fn compute_diagonal_cell(selected int) f32 {
	mut left := [1600]f32{}
	mut right := [1600]f32{}
	mut result := [1600]f32{}
	mut seed := u32(74755)
	for row in 0 .. side {
		for column in 0 .. side {
			temp := next_random(mut seed)
			remainder := i32(temp - (temp / 120) * 120)
			left[row * side + column] = rounded_div(f32(remainder - 60), f32(3.0))
		}
	}
	for row in 0 .. side {
		for column in 0 .. side {
			temp := next_random(mut seed)
			remainder := i32(temp - (temp / 120) * 120)
			right[row * side + column] = rounded_div(f32(remainder - 60), f32(3.0))
		}
	}
	for row in 0 .. side {
		for column in 0 .. side {
			mut total := f32(0)
			for inner in 0 .. side {
				product := rounded_mul(left[row * side + inner], right[inner * side + column])
				total = rounded_add(total, product)
			}
			result[row * side + column] = total
		}
	}
	return result[selected * side + selected]
}

fn write_unsigned(mut value u64, mut output &u8, offset int) int {
	unsafe {
		mut reversed := [24]u8{}
		mut count := 0
		for {
			reversed[count] = u8(48 + value % 10)
			count++
			value /= 10
			if value == 0 { break }
		}
		for index in 0 .. count {
			output[offset + index] = reversed[count - index - 1]
		}
		return count
	}
}

fn write_fixed_six(value f32, mut output &u8, offset int) int {
	unsafe {
		bits := math.f32_bits(value)
		exponent_bits := (bits >> 23) & 255
		fraction_bits := bits & 0x7fffff
		significand := if exponent_bits == 0 { u64(fraction_bits) } else { u64((u32(1) << 23) | fraction_bits) }
		shift := if exponent_bits == 0 { -149 } else { int(exponent_bits) - 150 }
		numerator := significand * u64(1000000)
		mut micros := u64(0)
		if shift >= 0 {
			micros = numerator << shift
		} else {
			denominator_shift := u32(-shift)
			if denominator_shift >= 64 {
				micros = 0
			} else {
				micros = numerator >> denominator_shift
				mask := (u64(1) << denominator_shift) - 1
				remainder := numerator & mask
				halfway := u64(1) << (denominator_shift - 1)
				if remainder > halfway || (remainder == halfway && (micros & 1) != 0) {
					micros++
				}
			}
		}
		mut position := offset
		if (bits >> 31) != 0 {
			output[position] = u8('-')
			position++
		}
		position += write_unsigned(micros / u64(1000000), mut output, position)
		output[position] = u8('.')
		position++
		fractional := u32(micros % u64(1000000))
		mut place := u32(100000)
		for place > 0 {
			output[position] = u8(48 + (fractional / place) % 10)
			position++
			place /= 10
		}
		output[position] = u8('\n')
		return position + 1 - offset
	}
}

@[export: 'floatmm']
pub fn floatmm(passes i64, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if passes < 0 || passes > max_passes {
			return -1
		}
		if passes == 0 {
			return 0
		}
		if output == nil {
			return -2
		}
		mut formatted := [max_output_bytes]u8{}
		mut required := 0
		for run in 0 .. int(passes) {
			diagonal := compute_diagonal_cell(run)
			required += write_fixed_six(diagonal, mut formatted[0], required)
		}
		if output_capacity < usize(required) {
			return -2
		}
		for index in 0 .. required {
			output[index] = formatted[index]
		}
		return i64(required)
	}
}
