@export("clear_leftmost_set_bit")
fn clear_leftmost_set_bit(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 2147483647: return -1
    if value == 0: return 0
    var temp = value
    var position: Int64 = 0
    while temp > 0:
        temp >>= 1
        position += 1
    let mask = ~(Int64(1) << (position - 1))
    return value & mask
