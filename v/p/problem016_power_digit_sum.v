module problem016_power_digit_sum

@[export: 'problem016_power_digit_sum']
pub fn problem016_power_digit_sum(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length != 2 { return -1 }
        base := values[0]
        exponent := values[1]
        if base < 0 || base > 9 || exponent < 0 || exponent > 1000 { return -1 }

        mut digits := [1001]i64{}
        mut digit_count := usize(1)
        digits[0] = base

        mut power := i64(1)
        for power < exponent {
            mut carry := i64(0)
            for index in 0 .. int(digit_count) {
                product := digits[index] * base + carry
                digits[index] = product % 10
                carry = product / 10
            }
            for carry > 0 {
                if digit_count >= 1001 { return -1 }
                digits[digit_count] = carry % 10
                digit_count++
                carry /= 10
            }
            power++
        }

        mut sum := i64(0)
        for index in 0 .. int(digit_count) {
            sum += digits[index]
        }
        return sum
    }
}
