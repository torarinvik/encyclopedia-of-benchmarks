package stanford_realmm

import "core:c"

ROWSIZE :: 40
CELL_COUNT :: ROWSIZE * ROWSIZE
MAX_PASSES :: 10
MAX_OUTPUT_BYTES :: 140

rounded_micro_units :: proc(bits: u64) -> u64 {
	exponent := int((bits >> 52) & 0x7ff)
	if exponent == 0 do return 0
	significand := (bits & 0x000f_ffff_ffff_ffff) | (u64(1) << 52)
	shift := 1075 - exponent
	if shift >= 74 do return 0
	low_product := (significand & 0xffff_ffff) * 1_000_000
	high_product := (significand >> 32) * 1_000_000
	middle := (low_product >> 32) + (high_product & 0xffff_ffff)
	limb0 := low_product & 0xffff_ffff
	limb1 := middle & 0xffff_ffff
	limb2 := (high_product >> 32) + (middle >> 32)
	quotient: u64
	half_bit: u64
	lower_nonzero: bool
	if shift < 64 {
		part := shift - 32
		quotient = (limb1 >> u64(part)) | (limb2 << u64(32 - part))
		half_bit = (limb1 >> u64(part - 1)) & 1
		lower_nonzero = limb0 != 0 || (limb1 & ((u64(1) << u64(part - 1)) - 1)) != 0
	} else if shift == 64 {
		quotient = limb2
		half_bit = limb1 >> 31
		lower_nonzero = limb0 != 0 || (limb1 & 0x7fff_ffff) != 0
	} else {
		part := shift - 64
		quotient = limb2 >> u64(part)
		half_bit = (limb2 >> u64(part - 1)) & 1
		lower_nonzero = limb0 != 0 || limb1 != 0 || (limb2 & ((u64(1) << u64(part - 1)) - 1)) != 0
	}
	if half_bit != 0 && (lower_nonzero || (quotient & 1) != 0) { quotient += 1 }
	return quotient
}

append_integer :: proc(value: u64, buffer: [^]u8, used: ^int) {
	mut remaining := value
	var reversed: [20]u8
	mut count := 0
	for {
		reversed[count] = u8(48 + remaining % 10)
		count += 1
		remaining /= 10
		if remaining == 0 do break
	}
	for count > 0 {
		count -= 1
		buffer[used^] = reversed[count]
		used^ += 1
	}
}

append_fixed :: proc(value: f64, buffer: [^]u8, used: ^int) {
	bits := transmute(u64)value
	if (bits >> 63) != 0 {
		buffer[used^] = u8('-')
		used^ += 1
	}
	scaled := rounded_micro_units(bits & 0x7fff_ffff_ffff_ffff)
	append_integer(scaled / 1_000_000, buffer, used)
	buffer[used^] = u8('.')
	used^ += 1
	fraction := scaled % 1_000_000
	place := u64(100_000)
	for place > 0 {
		buffer[used^] = u8(48 + fraction / place)
		used^ += 1
		fraction %= place
		place /= 10
	}
}

@(export, link_name="stanford_realmm")
stanford_realmm :: proc "c" (pass_count: i64, output: [^]u8,
		output_capacity: c.size_t) -> i64 {
	if pass_count < 1 || pass_count > MAX_PASSES do return -1
	if output == nil do return -2

	mut a: [CELL_COUNT]f64
	mut b: [CELL_COUNT]f64
	mut product: [CELL_COUNT]f64
	var staged: [MAX_OUTPUT_BYTES]u8
	mut used := 0
	for pass := 0; pass < int(pass_count); pass += 1 {
		mut seed := i64(74755)
		for index := 0; index < CELL_COUNT; index += 1 {
			seed = (seed * 1309 + 13849) & 65535
			temp := seed
			residue := temp - (temp / 120) * 120 - 60
			a[index] = f64(residue) / 3.0
		}
		for index := 0; index < CELL_COUNT; index += 1 {
			seed = (seed * 1309 + 13849) & 65535
			temp := seed
			residue := temp - (temp / 120) * 120 - 60
			b[index] = f64(residue) / 3.0
		}

		for row := 0; row < ROWSIZE; row += 1 {
			for column := 0; column < ROWSIZE; column += 1 {
				mut sum := f64(0.0)
				for inner := 0; inner < ROWSIZE; inner += 1 {
					sum = sum + a[row * ROWSIZE + inner] * b[inner * ROWSIZE + column]
				}
				product[row * ROWSIZE + column] = sum
			}
		}
		append_fixed(product[pass * ROWSIZE + pass], &staged[0], &used)
		staged[used] = 10
		used += 1
	}

	if output_capacity < c.size_t(used) do return -2
	for index := 0; index < used; index += 1 { output[index] = staged[index] }
	return i64(used)
}
