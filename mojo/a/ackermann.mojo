fn ackermann_value(m: Int64, n: Int64) -> Int64:
    if m == 0:
        return n + 1
    if n == 0:
        return ackermann_value(m - 1, 1)
    return ackermann_value(m - 1, ackermann_value(m, n - 1))

@export("ackermann")
fn ackermann(m: Int64, n: Int64) abi("C") -> Int64:
    if m < 0 or m > 3 or n < 0 or n > 5:
        return -1
    return ackermann_value(m, n)
