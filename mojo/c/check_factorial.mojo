@export("check_factorial")
fn check_factorial(n: Int64) abi("C") -> Int64:
    if n <= 0: return 0
    var value = n
    var divisor: Int64 = 2
    while value % divisor == 0:
        value //= divisor
        divisor += 1
    return 1 if value == 1 else 0
