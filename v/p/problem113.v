// Count non-bouncy positive integers with at most the requested digits.
module problem113

const max_digits = i64(100)

fn choose_integer(n i64, r i64) i64 {
    mut result := i64(1)
    mut i := i64(1)
    for i <= r {
        result = result * (n + 1 - i) / i
        i++
    }
    return result
}

fn non_bouncy_exact(digits i64) i64 {
    return choose_integer(8 + digits, digits) + choose_integer(9 + digits, digits) - 10
}

@[export: 'problem113']
pub fn problem113(num_digits i64) i64 {
    if num_digits > max_digits { return -1 }
    mut total := i64(0)
    mut digits := i64(1)
    for digits <= num_digits {
        total += non_bouncy_exact(digits)
        digits++
    }
    return total
}
