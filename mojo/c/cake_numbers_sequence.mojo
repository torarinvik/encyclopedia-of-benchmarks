@export("cake_numbers_sequence")
fn cake_numbers_sequence(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 2_000_000:
        return -1
    return (n * n * n + 5 * n + 6) // 6
