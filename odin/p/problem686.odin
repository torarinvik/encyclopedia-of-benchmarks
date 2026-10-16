package problem686

MAX_POSITION :: i64(678_910)
LOG10_2 :: f64(0.30102999566398114)
LOWER_LIMIT :: f64(0.08990511143939792)
UPPER_LIMIT :: f64(0.09342168516223506)
ROUND_SCALE :: f64(1_000_000_000_000_000.0)

rounded_decimal_part :: proc(exponent: i64) -> f64 {
    logarithm := LOG10_2 * f64(exponent)
    integer_part := i64(logarithm)
    scaled := (logarithm - f64(integer_part)) * ROUND_SCALE
    rounded := i64(scaled)
    remainder := scaled - f64(rounded)
    if remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0) { rounded += 1 }
    return f64(rounded) / ROUND_SCALE
}

@(export)
problem686 :: proc "c" (number: i64) -> i64 {
    if number < 1 || number > MAX_POSITION do return -1
    power, position, previous := i64(90), i64(0), i64(0)
    for position < number {
        difference := rounded_decimal_part(power)
        if difference >= UPPER_LIMIT { power += 93 }
        else if difference < LOWER_LIMIT { power += 196 }
        else { previous = power; power += 196; position += 1 }
    }
    return previous
}
