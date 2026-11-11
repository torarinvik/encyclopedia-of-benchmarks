def phi(value: UInt64) -> UInt64:
    var result = value
    var remaining = value
    var factor = UInt64(2)
    while factor <= remaining // factor:
        if remaining % factor == 0:
            result -= result // factor
            while remaining % factor == 0:
                remaining //= factor
        factor += UInt64(1 if factor == 2 else 2)
    if remaining > 1:
        result -= result // remaining
    return result

@export("lcm_sum")
def lcm_sum(input: Int64) abi("C") -> Int64:
    if input < 1 or input > 65535:
        return -1
    var n = UInt64(input)
    var sum = UInt64(1)
    var divisor = UInt64(1)
    while divisor <= n // divisor:
        if n % divisor == 0:
            sum += divisor * phi(divisor)
            var paired = n // divisor
            if paired != divisor:
                sum += paired * phi(paired)
        divisor += 1
    return Int64((sum * n) // 2)
