@export("factorial")
fn factorial(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 20: return -1
    var product: Int64 = 1
    for factor in range(2, n + 1): product *= factor
    return product
