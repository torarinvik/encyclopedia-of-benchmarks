@export("armstrong_digit_cubes")
fn armstrong_digit_cubes(n: Int64) abi("C") -> Int64:
    if n < -2147483648 or n > 2147483647: return -1
    let original = n
    var magnitude = n
    if magnitude < 0: magnitude = -magnitude
    var total: Int64 = 0
    while magnitude > 0:
        let digit = magnitude % 10
        total += digit * digit * digit
        magnitude /= 10
    if original < 0: total = -total
    if total == original: return 1
    return 0
