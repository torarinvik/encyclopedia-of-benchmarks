def is_prime(value: Int64) -> Bool:
    if value == 2:
        return True
    if value < 2 or value % 2 == 0:
        return False
    var divisor: Int64 = 3
    while divisor <= value // divisor:
        if value % divisor == 0:
            return False
        divisor += 2
    return True

def digit_sum(value_arg: Int64) -> Int64:
    var value = value_arg
    var sum: Int64 = 0
    while value != 0:
        sum += value % 10
        value //= 10
    return sum

def prime_factor_digit_sum(value: Int64) -> Int64:
    var sum: Int64 = 0
    var remainder = value
    var factor: Int64 = 2
    while factor <= remainder // factor:
        while remainder % factor == 0:
            sum += digit_sum(factor)
            remainder //= factor
        factor += 1
    if remainder > 1:
        sum += digit_sum(remainder)
    return sum

@export("smith_number")
def smith_number(value: Int64) abi("C") -> Int64:
    if value < 1 or value > 2147395599:
        return -1
    if is_prime(value):
        return 0
    return 1 if digit_sum(value) == prime_factor_digit_sum(value) else 0
