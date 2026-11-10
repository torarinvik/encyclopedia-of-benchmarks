package number_of_digits

// Count base-10 digits in the magnitude, including for minimum i64.
@(export)
number_of_digits :: proc "c" (value: i64) -> i64 {
    magnitude: u64
    if value < 0 { magnitude = u64(-(value + 1)) + 1 } else { magnitude = u64(value) }
    if magnitude < 10 do return 1
    digits := i64(1)
    for magnitude >= 10000 {
        magnitude /= 10000
        digits += 4
    }
    if magnitude < 10 do return digits
    if magnitude < 100 do return digits + 1
    return digits + (2 if magnitude < 1000 else 3)
}
