fn gcd_i64(left_arg: Int64, right_arg: Int64) -> Int64:
    var left = left_arg
    var right = right_arg
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

@export("catalan_number")
fn catalan_number(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 35: return -1
    var value: Int64 = 1
    for index in range(1, n + 1):
        var numerator = 4 * index - 2
        var denominator = index + 1
        let common = gcd_i64(numerator, denominator)
        numerator /= common
        denominator /= common
        value = (value // denominator) * numerator
    return value
