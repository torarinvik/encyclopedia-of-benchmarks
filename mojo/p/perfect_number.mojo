@export("perfect_number")
def perfect_number(n: Int64) abi("C") -> Int64:
    if n <= 1:
        return 0
    if n > 1000000000000:
        return -1
    var number = UInt64(n)
    var stride = 1 + (number & 1)
    var divisor_sum = UInt64(1)
    if stride == 1 and number >= 4:
        var half = number >> 1
        divisor_sum = 3 if half == 2 else 3 + half
    var factor = UInt64(3)
    while True:
        var partner = number / factor
        if factor > partner:
            break
        if partner * factor == number:
            divisor_sum += factor
            if partner != factor:
                divisor_sum += partner
            if divisor_sum > number:
                return 0
        factor += stride
    return 1 if divisor_sum == number else 0
