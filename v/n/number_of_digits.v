module number_of_digits

// Count base-10 digits in the magnitude, including for minimum i64.
@[export: 'number_of_digits']
pub fn number_of_digits(value i64) i64 {
    mut magnitude := u64(0)
    if value < 0 { magnitude = u64(-(value + 1)) + u64(1) } else { magnitude = u64(value) }
    mut digits := i64(1)
    for magnitude >= 10 {
        magnitude /= u64(10)
        digits++
    }
    return digits
}
