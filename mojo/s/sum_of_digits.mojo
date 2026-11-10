@export("sum_of_digits")
def sum_of_digits(value: Int64) abi("C") -> Int64:
    if value < -2147483648 or value > 2147483647: return -1
    var magnitude = UInt32(-value if value < 0 else value)
    var remaining = magnitude
    var total = UInt32(0)
    while remaining >= 10:
        var next_quotient = remaining // 10
        remaining //= 100
        total += next_quotient + remaining
    return Int64(magnitude - 9 * total)
