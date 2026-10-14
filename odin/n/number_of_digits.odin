package number_of_digits

// Count base-10 digits in the magnitude, including for minimum i64.
@(export)
number_of_digits :: proc "c" (value: i64) -> i64 {
    magnitude: u64
    if value < 0 { magnitude = u64(-(value + 1)) + 1 } else { magnitude = u64(value) }
    digits := i64(1)
    for magnitude >= 10 {
        magnitude /= 10
        digits += 1
    }
    return digits
}
