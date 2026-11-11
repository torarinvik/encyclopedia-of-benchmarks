def is_composite(n: Int64) -> Bool:
    if n < 4: return False
    var divisor: Int64 = 2
    while divisor <= n // divisor:
        if n % divisor == 0: return True
        divisor += 1
    return False

def mod_power(base: Int64, exponent: Int64, modulus: Int64) -> Int64:
    var result: Int64 = 1
    var power = base
    var remaining = exponent
    while remaining > 0:
        if remaining % 2 != 0:
            result = (result * power) % modulus
        remaining //= 2
        if remaining > 0:
            power = (power * power) % modulus
    return result

def gcd(left_arg: Int64, right_arg: Int64) -> Int64:
    var left = left_arg
    var right = right_arg
    while right != 0:
        var remainder = left % right
        left = right
        right = remainder
    return left

@export("carmichael_number")
def carmichael_number(value: Int64) abi("C") -> Int64:
    if value < 1 or value > 10000: return -1
    if value < 3 or not is_composite(value): return 0
    var base: Int64 = 2
    while base < value:
        if gcd(base, value) == 1 and mod_power(base, value - 1, value) != 1: return 0
        base += 1
    return 1
