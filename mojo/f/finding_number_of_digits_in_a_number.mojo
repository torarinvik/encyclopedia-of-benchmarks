@export("finding_number_of_digits_in_a_number")
fn finding_number_of_digits_in_a_number(value: Int64) abi("C") -> Int64:
    if value < 0: return -1
    var remaining = UInt64(value)
    var count: Int64 = 0
    while remaining != 0:
        remaining /= 10
        count += 1
    return count
