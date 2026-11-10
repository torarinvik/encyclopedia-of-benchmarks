@export("hamming_distance")
def hamming_distance(left: UInt64, right: UInt64) abi("C") -> Int64:
    var differing = left ^ right
    var pairs = differing - ((differing >> 1) & 0x5555555555555555)
    var nibbles = (pairs & 0x3333333333333333) + ((pairs >> 2) & 0x3333333333333333)
    var bytes = (nibbles + (nibbles >> 4)) & 0x0f0f0f0f0f0f0f0f
    return Int64((bytes * 0x0101010101010101) >> 56)
