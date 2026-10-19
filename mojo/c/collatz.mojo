@export("collatz")
fn collatz(n: Int64) abi("C") -> Int64:
    if n < 1 or n > 1000000: return -1
    var value = n
    var steps: Int64 = 0
    while value != 1:
        value = value / 2 if value % 2 == 0 else 3 * value + 1
        steps += 1
    return steps
