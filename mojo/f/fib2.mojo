fn fib2_value(n: Int64) -> Int64:
    if n < 2: return 1
    return fib2_value(n - 2) + fib2_value(n - 1)

@export("fib2")
fn fib2(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 30: return -1
    return fib2_value(n)
