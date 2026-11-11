@export("aliquot_sum")
def aliquot_sum(n: Int64) abi("C") -> Int64:
    if n < 0:
        return -1
    var sum: Int64 = 0
    var divisor: Int64 = 1
    while divisor <= n // 2:
        if n % divisor == 0:
            if sum > 9223372036854775807 - divisor:
                return -1
            sum += divisor
        divisor += 1
    return sum
