@export("first_different_bit")
fn first_different_bit(x: Int64, y: Int64) abi("C") -> Int64:
    if x < -2147483648 or x > 2147483647 or y < -2147483648 or y > 2147483647: return -1
    var difference = UInt32(Int32(x)) ^ UInt32(Int32(y))
    var index: Int64 = 0
    while index < 32 and (difference & 1) == 0:
        index += 1
        difference >>= 1
    return index
