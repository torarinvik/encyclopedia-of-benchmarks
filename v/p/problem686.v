module problem686

const max_position = i64(678910)
const log10_two = f64(0.30102999566398114)
const lower_limit = f64(0.08990511143939792)
const upper_limit = f64(0.09342168516223506)
const round_scale = f64(1000000000000000.0)

fn rounded_decimal_part(exponent i64) f64 {
	logarithm := log10_two * f64(exponent)
	integer_part := i64(logarithm)
	scaled := (logarithm - f64(integer_part)) * round_scale
	mut rounded := i64(scaled)
	remainder := scaled - f64(rounded)
	if remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0) { rounded++ }
	return f64(rounded) / round_scale
}

@[export: 'problem686']
pub fn problem686(number i64) i64 {
	if number < 1 || number > max_position { return -1 }
	mut power := i64(90)
	mut position := i64(0)
	mut previous := i64(0)
	for position < number {
		difference := rounded_decimal_part(power)
		if difference >= upper_limit { power += 93 }
		else if difference < lower_limit { power += 196 }
		else { previous = power; power += 196; position++ }
	}
	return previous
}
