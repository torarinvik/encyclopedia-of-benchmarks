@export("binary_count_trailing_zeros")
fn binary_count_trailing_zeros(value: Int64) abi("C") -> Int64:
    if value < 0: return -1
    var n = value; var count: Int64 = 0
    while n > 0 and (n & 1) == 0: n >>= 1; count += 1
    return count
