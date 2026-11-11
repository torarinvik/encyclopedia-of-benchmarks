def is_prime_trial(value: Int64) -> Bool:
    if value < 2:
        return False
    var divisor: Int64 = 2
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 1
    return True

@export("greatest_prime_factor")
def greatest_prime_factor(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 1000000:
        return -1
    if n < 2 or is_prime_trial(n):
        return n
    var quotient = n
    var largest: Int64 = 0
    var factor: Int64 = 2
    while quotient != 1:
        if is_prime_trial(factor) and quotient % factor == 0:
            largest = factor
            quotient //= factor
        else:
            factor += 1
    return largest
