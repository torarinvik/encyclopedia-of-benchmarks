@export("fibonacci")
fn fibonacci(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 92: return -1
    if n == 0: return 0
    var previous: Int64 = 0
    var current: Int64 = 1
    for i in range(1, n):
        let next = previous + current
        previous = current
        current = next
    return current
