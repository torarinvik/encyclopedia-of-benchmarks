@export("fib")
fn fib(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 90: return -1
    var previous: Int64 = 1
    var current: Int64 = 2
    for i in range(n):
        let next = previous + current
        previous = current
        current = next
    return previous
