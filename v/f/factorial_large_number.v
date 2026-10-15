module factorial_large_number

const max_n = 100
const max_digits = 160

@[export: 'factorial_large_number']
pub fn factorial_large_number(n i64, output &u8, output_capacity usize) i64 {
    if n < 0 || n > max_n { return -1 }
    mut digits := [max_digits]i64{}
    digits[0] = 1
    mut digit_count := 1
    mut factor := i64(2)
    for factor <= n {
        mut carry := i64(0)
        for index in 0 .. digit_count {
            product := digits[index] * factor + carry
            digits[index] = product % 10
            carry = product / 10
        }
        for carry != 0 {
            digits[digit_count] = carry % 10
            digit_count++
            carry /= 10
        }
        factor++
    }
    if output_capacity < digit_count { return -2 }
    unsafe {
        for index in 0 .. digit_count {
            output[index] = u8(48 + digits[digit_count - index - 1])
        }
    }
    return i64(digit_count)
}
