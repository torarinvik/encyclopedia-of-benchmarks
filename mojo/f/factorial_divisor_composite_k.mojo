fn factorial_divisor_composite_k_valuation(n: UInt64, prime: UInt64) -> UInt64:
    var quotient = n
    var total: UInt64 = 0
    while quotient != 0:
        quotient /= prime
        total += quotient
    return total


@export("factorial_divisor_composite_k")
fn factorial_divisor_composite_k(n: UInt64, k: UInt64) abi("C") -> Int64:
    if n > 1_000_000_000_000 or k < 4 or k > 1_000_000:
        return -1

    var remaining = k
    var divisor: UInt64 = 2
    var answer = n
    var composite = False
    while divisor <= remaining / divisor:
        if remaining % divisor == 0:
            composite = True
            var exponent: UInt64 = 0
            while remaining % divisor == 0:
                remaining /= divisor
                exponent += 1
            var candidate = factorial_divisor_composite_k_valuation(n, divisor) / exponent
            if candidate < answer:
                answer = candidate
        divisor += 1

    if not composite:
        return -1
    if remaining > 1:
        var candidate = factorial_divisor_composite_k_valuation(n, remaining)
        if candidate < answer:
            answer = candidate
    return answer.cast[Int64]()
