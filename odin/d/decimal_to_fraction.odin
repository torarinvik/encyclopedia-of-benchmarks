package decimal_to_fraction

import "core:c"

POWERS10 :: [5]i64{1, 10, 100, 1000, 10000}
POWERS5 :: [5]i64{1, 5, 25, 125, 625}

store_i64_le :: proc(output: [^]u8, offset: c.size_t, value: i64) {
    bits := u64(value)
    for byte := c.size_t(0); byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> (8 * byte)) & 255)
    }
}

gcd_positive :: proc(a_input, b_input: i64) -> i64 {
    a, b := a_input, b_input
    for b != 0 {
        remainder := a % b
        a, b = b, remainder
    }
    return a
}

@(export)
decimal_to_fraction :: proc "c" (values: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length != 2 do return -1
    mantissa, places_value := values[0], values[1]
    if places_value < 0 || places_value > 4 do return -1
    places := int(places_value)
    scale := POWERS10[places]
    maximum_mantissa := i64(1_000_000) * scale
    if mantissa < -maximum_mantissa || mantissa > maximum_mantissa || mantissa % POWERS5[places] != 0 do return -1
    if output == nil || capacity < 16 do return -2

    decimal := f64(mantissa) / f64(scale)
    numerator := i64(0)
    denominator := i64(1)
    if decimal - f64(i64(decimal)) == 0.0 {
        numerator = i64(decimal)
    } else {
        digits := places
        magnitude := if mantissa < 0 { -mantissa } else { mantissa }
        for digits > 0 && magnitude % 10 == 0 {
            magnitude /= 10
            digits -= 1
        }
        numerator = i64(decimal * f64(POWERS10[digits]))
        denominator = POWERS10[digits]
        abs_numerator := if numerator < 0 { -numerator } else { numerator }
        gcd := gcd_positive(abs_numerator, denominator)
        numerator /= gcd
        denominator /= gcd
    }
    store_i64_le(output, 0, numerator)
    store_i64_le(output, 8, denominator)
    return 16
}
