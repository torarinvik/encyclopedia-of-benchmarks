@export("number_of_digits")
def number_of_digits(value: Int64) abi("C") -> Int64:
    var magnitude = UInt64(-(value + 1)) + 1 if value < 0 else UInt64(value)
    if magnitude < 10:
        return 1
    var digits: Int64 = 1
    while magnitude >= 10000:
        magnitude = magnitude // 10000
        digits += 4
    if magnitude < 10:
        return digits
    if magnitude < 100:
        return digits + 1
    return digits + Int64(2 if magnitude < 1000 else 3)
