fn fib_recursive_value(n: Int64) -> Int64:
    if n < 2: return n
    return fib_recursive_value(n - 1) + fib_recursive_value(n - 2)

@export("fibonacci_recursive")
fn fibonacci_recursive(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 30: return -1
    return fib_recursive_value(n)
