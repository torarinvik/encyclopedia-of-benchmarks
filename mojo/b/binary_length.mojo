@export("binary_length")
fn binary_length(value: Int64) abi("C") -> Int64:
    if value <= 0 or value > 2_147_483_647: return -1
    var bits: Int64 = 0
    var n = value
    while n > 0: bits += 1; n >>= 1
    return bits
