@export("matchstick_triangle_sequence")
fn matchstick_triangle_sequence(n: Int64) abi("C") -> Int64:
    if n < 0 or n > 1_000_000: return -1
    return (n * (n + 2) * (2 * n + 1)) / 8
