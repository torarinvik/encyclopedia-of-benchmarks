@export("hamming_weight")
def hamming_weight(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 4294967295:
        return -1
    var number = UInt32(value)
    var pairs = number - ((number >> 1) & 0x55555555)
    var nibbles = (pairs & 0x33333333) + ((pairs >> 2) & 0x33333333)
    var bytes = (nibbles + (nibbles >> 4)) & 0x0f0f0f0f
    return Int64((bytes * 0x01010101) >> 24)
