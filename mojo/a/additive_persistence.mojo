@export("additive_persistence")
fn additive_persistence(input: Int64) abi("C") -> Int64:
    if input < 0:
        return -1
    var value = input
    var steps: Int64 = 0
    while value >= 10:
        var remaining = value
        var sum: Int64 = 0
        while remaining > 0:
            sum += remaining % 10
            remaining /= 10
        value = sum
        steps += 1
    return steps
