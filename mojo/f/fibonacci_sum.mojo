fn fibonacci_sum_at(index: UInt64) -> Int64:
    if index == 0: return 0
    var previous: Int64 = 0
    var current: Int64 = 1
    for i in range(UInt64(1), index):
        let next = previous + current
        previous = current
        current = next
    return current

@export("fibonacci_sum")
fn fibonacci_sum(start: UInt64, end: UInt64) abi("C") -> Int64:
    if end > 90 or start > end: return -1
    return fibonacci_sum_at(end + 2) - fibonacci_sum_at(start + 1)
