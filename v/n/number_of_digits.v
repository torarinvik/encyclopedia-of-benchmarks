module number_of_digits

// Count base-10 digits in the magnitude, including for minimum i64.
@[export: 'number_of_digits']
pub fn number_of_digits(value i64) i64 {
    mut magnitude := u64(0)
    if value < 0 { magnitude = u64(-(value + 1)) + u64(1) } else { magnitude = u64(value) }
    if magnitude < 10 { return 1 }
    mut digits := i64(1)
    for magnitude >= 10000 {
        magnitude /= u64(10000)
        digits += 4
    }
    if magnitude < 10 { return digits }
    if magnitude < 100 { return digits + 1 }
    return digits + if magnitude < 1000 { i64(2) } else { i64(3) }
}
