// Return the unpadded decimal suffix of the non-Mersenne prime expression.
module problem97

const max_digits = i64(18)
const power_exponent = i64(7830457)

fn multiply_mod(left_value i64, right_value i64, modulus i64) i64 {
    mut left := left_value
    mut right := right_value
    mut result_value := i64(0)
    for right > 0 {
        if right % 2 != 0 {
            result_value = (result_value + left) % modulus
        }
        left = (left + left) % modulus
        right /= 2
    }
    return result_value
}

@[export: 'problem97']
pub fn problem97(digits i64) i64 {
    if digits < 0 || digits > max_digits {
        return -1
    }
    mut modulus := i64(1)
    mut index := i64(0)
    for index < digits {
        modulus *= 10
        index++
    }
    mut power := i64(1) % modulus
    mut base := i64(2) % modulus
    mut exponent := power_exponent
    for exponent > 0 {
        if exponent % 2 != 0 {
            power = multiply_mod(power, base, modulus)
        }
        base = multiply_mod(base, base, modulus)
        exponent /= 2
    }
    return (multiply_mod(28433, power, modulus) + 1) % modulus
}
