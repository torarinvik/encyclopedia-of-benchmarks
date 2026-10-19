@export("sum_of_digits")
fn sum_of_digits(value: Int64) abi("C") -> Int64:
    if value < -2147483648 or value > 2147483647: return -1
    var magnitude = value
    if magnitude < 0: magnitude = -magnitude
    var total: Int64 = 0
    while magnitude > 0:
        total += magnitude % 10
        magnitude /= 10
    return total
