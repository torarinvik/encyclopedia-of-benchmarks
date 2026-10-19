@export("factorial_trailing_zeroes")
fn factorial_trailing_zeroes(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 1000000000: return -1
    var current = n
    var total: Int64 = 0
    while current > 0:
        current /= 5
        total += current
    return total
