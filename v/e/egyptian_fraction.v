module egyptian_fraction

// Return source-ordered unit-fraction denominators as little-endian i32s.
@[export: 'egyptian_fraction']
pub fn egyptian_fraction(input &i64, length usize, mut output &u8, output_capacity usize) i64 {
	if unsafe { input == nil } || length != 2 { return -1 }
	unsafe {
		mut numerator := input[0]
		mut denominator := input[1]
		if numerator < 0 || denominator < 1 || denominator > 10 || numerator > denominator { return -1 }

		mut terms := [10]u32{}
		mut count := 0
		for numerator != 0 {
			mut unit_denominator := denominator / numerator
			if denominator % numerator != 0 { unit_denominator++ }
			terms[count] = u32(unit_denominator)
			count++
			numerator = numerator * unit_denominator - denominator
			denominator = denominator * unit_denominator
		}
		required := usize(count * 4)
		if output_capacity < required || (required > 0 && output == nil) { return -2 }
		for index in 0 .. count {
			value := terms[index]
			for byte in 0 .. 4 { output[index * 4 + byte] = u8(value >> (8 * byte)) }
		}
		return i64(required)
	}
}
