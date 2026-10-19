@export("climbing_stairs")
fn climbing_stairs(steps: Int64) abi("C") -> Int64:
    if steps < 1 or steps > 45: return -1
    var previous: Int64 = 1
    var current: Int64 = 1
    for _ in range(2, steps + 1):
        let next = previous + current
        previous = current
        current = next
    return current
