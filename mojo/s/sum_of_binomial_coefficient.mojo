@export("sum_of_binomial_coefficient")
fn sum_of_binomial_coefficient(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 30: return -1
    return Int64(1) << UInt(n)
