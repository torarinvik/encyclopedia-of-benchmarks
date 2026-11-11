@export("reverse_bits")
def reverse_bits(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 4294967295:
        return -1
    var remaining = UInt32(value)
    var reversed_bits: UInt32 = 0
    for _ in range(32):
        reversed_bits = (reversed_bits << 1) | (remaining & UInt32(1))
        remaining = remaining >> 1
    return Int64(reversed_bits)
