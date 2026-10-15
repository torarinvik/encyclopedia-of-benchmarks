module decimal_to_fraction

const powers10 = [5]i64{ 1, 10, 100, 1000, 10000 }
const powers5 = [5]i64{ 1, 5, 25, 125, 625 }

fn store_i64_le(output &u8, offset usize, value i64) {
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8((value >> (8 * int(byte))) & 255) }
	}
}

fn gcd_positive(a_input i64, b_input i64) i64 {
	mut a := a_input
	mut b := b_input
	for b != 0 {
		remainder := a % b
		a = b
		b = remainder
	}
	return a
}

@[export: 'decimal_to_fraction']
pub fn decimal_to_fraction(values &i64, length usize, output &u8, capacity usize) i64 {
	if length != 2 { return -1 }
	mantissa := unsafe { values[0] }
	places_value := unsafe { values[1] }
	if places_value < 0 || places_value > 4 { return -1 }
	places := int(places_value)
	scale := powers10[places]
	maximum_mantissa := i64(1000000) * scale
	if mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % powers5[places] != 0 { return -1 }
	if capacity < 16 { return -2 }

	decimal := f64(mantissa) / f64(scale)
	mut numerator := i64(0)
	mut denominator := i64(1)
	if decimal - f64(i64(decimal)) == 0.0 {
		numerator = i64(decimal)
	} else {
		mut digits := places
		mut magnitude := if mantissa < 0 { -mantissa } else { mantissa }
		for digits > 0 && magnitude % 10 == 0 {
			magnitude /= 10
			digits--
		}
		numerator = i64(decimal * f64(powers10[digits]))
		denominator = powers10[digits]
		gcd := gcd_positive(if numerator < 0 { -numerator } else { numerator }, denominator)
		numerator /= gcd
		denominator /= gcd
	}
	store_i64_le(output, 0, numerator)
	store_i64_le(output, 8, denominator)
	return 16
}
