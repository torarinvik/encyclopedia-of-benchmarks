fn is_composite(n: Int64) -> Bool:
    if n < 4: return False
    var divisor: Int64 = 2
    while divisor <= n // divisor:
        if n % divisor == 0: return True
        divisor += 1
    return False

fn mod_power(base: Int64, exponent: Int64, modulus: Int64) -> Int64:
    if exponent == 0: return 1
    let half = mod_power(base, exponent // 2, modulus) % modulus
    var result = (half * half) % modulus
    if exponent % 2 != 0: result = (result * base) % modulus
    return result

fn gcd(left_arg: Int64, right_arg: Int64) -> Int64:
    var left = left_arg
    var right = right_arg
    while right != 0:
        let remainder = left % right
        left = right
        right = remainder
    return left

@export("carmichael_number")
fn carmichael_number(value: Int64) abi("C") -> Int64:
    if value < 1 or value > 10000: return -1
    if value < 3 or not is_composite(value): return 0
    for base in range(2, value):
        if gcd(base, value) == 1 and mod_power(base, value - 1, value) != 1: return 0
    return 1
