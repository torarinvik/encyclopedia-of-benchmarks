def gcd_factor(left_value: Int64, right_value: Int64) -> Int64:
    var left = left_value
    var right = right_value
    while right != 0:
        var remainder = left % right
        left = right
        right = remainder
    return left

def next_factor(x: Int64, n: Int64) -> Int64:
    return (x * x + 1) % n

@export("pollards_rho_factorizing")
def pollards_rho_factorizing(n: Int64) abi("C") -> Int64:
    if n < 2 or n > 46340:
        return -1
    var x = Int64(2)
    var y = Int64(2)
    var divisor = Int64(1)
    while divisor == 1:
        x = next_factor(x, n)
        y = next_factor(next_factor(y, n), n)
        var difference = x - y if x >= y else y - x
        divisor = gcd_factor(difference, n)
    return divisor
