@export("binary_palindrome_check")
def binary_palindrome_check(value: Int64) abi("C") -> Int64:
    if value < -2_147_483_648 or value > 2_147_483_647:
        return -1
    if value < 0:
        return 0
    var remaining = value
    var reversed_bits: Int64 = 0
    while remaining > 0:
        reversed_bits = (reversed_bits << 1) | (remaining & 1)
        remaining = remaining >> 1
    if reversed_bits == value:
        return 1
    return 0
