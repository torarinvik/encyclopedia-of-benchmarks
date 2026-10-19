module stanford_realmm

import math

const row_size = 40
const cell_count = row_size * row_size
const max_passes = 10
const max_output_bytes = 140

fn rounded_micro_units(bits u64) u64 {
	exponent := int((bits >> 52) & u64(0x7ff))
	if exponent == 0 { return 0 }
	significand := (bits & u64(0x000f_ffff_ffff_ffff)) | (u64(1) << 52)
	shift := 1075 - exponent
	if shift >= 74 { return 0 }
	low_product := (significand & u64(0xffff_ffff)) * 1_000_000
	high_product := (significand >> 32) * 1_000_000
	middle := (low_product >> 32) + (high_product & u64(0xffff_ffff))
	limb0 := low_product & u64(0xffff_ffff)
	limb1 := middle & u64(0xffff_ffff)
	limb2 := (high_product >> 32) + (middle >> 32)
	mut quotient := u64(0)
	mut half_bit := u64(0)
	mut lower_nonzero := false
	if shift < 64 {
		part := shift - 32
		quotient = (limb1 >> u64(part)) | (limb2 << u64(32 - part))
		half_bit = (limb1 >> u64(part - 1)) & u64(1)
		lower_nonzero = limb0 != 0 || (limb1 & ((u64(1) << u64(part - 1)) - u64(1))) != 0
	} else if shift == 64 {
		quotient = limb2
		half_bit = limb1 >> 31
		lower_nonzero = limb0 != 0 || (limb1 & u64(0x7fff_ffff)) != 0
	} else {
		part := shift - 64
		quotient = limb2 >> u64(part)
		half_bit = (limb2 >> u64(part - 1)) & u64(1)
		lower_nonzero = limb0 != 0 || limb1 != 0 || (limb2 & ((u64(1) << u64(part - 1)) - u64(1))) != 0
	}
	if half_bit != 0 && (lower_nonzero || (quotient & u64(1)) != 0) { quotient++ }
	return quotient
}

fn append_integer(mut buffer [max_output_bytes]u8, mut used int, value u64) {
	mut remaining := value
	mut reversed := [20]u8{}
	mut count := 0
	for {
		unsafe { reversed[count] = u8(`0`) + u8(remaining % u64(10)) }
		count++
		remaining /= u64(10)
		if remaining == 0 { break }
	}
	for count > 0 {
		count--
		buffer[used] = reversed[count]
		used++
	}
}

fn append_fixed(mut buffer [max_output_bytes]u8, mut used int, value f64) {
	bits := math.f64_bits(value)
	if (bits >> 63) != 0 {
		unsafe { buffer[used] = u8(`-`) }
		used++
	}
	scaled := rounded_micro_units(bits & u64(0x7fff_ffff_ffff_ffff))
	append_integer(mut buffer, mut used, scaled / u64(1_000_000))
	unsafe { buffer[used] = u8(`.`) }
	used++
	mut fraction := scaled % u64(1_000_000)
	mut place := u64(100_000)
	for place > 0 {
		unsafe { buffer[used] = u8(`0`) + u8(fraction / place) }
		used++
		fraction %= place
		place /= u64(10)
	}
}

@[export: 'stanford_realmm']
pub fn stanford_realmm(pass_count i64, mut output &u8, output_capacity usize) i64 {
	if pass_count < 1 || pass_count > i64(max_passes) { return -1 }
	if unsafe { output == nil } { return -2 }

	mut a := [cell_count]f64{}
	mut b := [cell_count]f64{}
	mut product := [cell_count]f64{}
	mut staged := [max_output_bytes]u8{}
	mut used := 0
	for pass in 0 .. int(pass_count) {
		mut seed := i64(74755)
		for index in 0 .. cell_count {
			seed = (seed * 1309 + 13849) & 65535
			temp := seed
			residue := temp - (temp / 120) * 120 - 60
			a[index] = f64(residue) / 3.0
		}
		for index in 0 .. cell_count {
			seed = (seed * 1309 + 13849) & 65535
			temp := seed
			residue := temp - (temp / 120) * 120 - 60
			b[index] = f64(residue) / 3.0
		}

		for row in 0 .. row_size {
			for column in 0 .. row_size {
				mut sum := f64(0.0)
				for inner in 0 .. row_size {
					sum = sum + a[row * row_size + inner] * b[inner * row_size + column]
				}
				product[row * row_size + column] = sum
			}
		}
		append_fixed(mut staged, mut used, product[pass * row_size + pass])
		unsafe { staged[used] = 10 }
		used++
	}

	if output_capacity < used { return -2 }
	for index in 0 .. used { unsafe { output[index] = staged[index] } }
	return i64(used)
}
