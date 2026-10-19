@export("circular_left_shift")
fn circular_left_shift(value: UInt64, shift: UInt64) abi("C") -> Int64:
    let mask: UInt64 = 9007199254740991
    if value > mask or shift > 53: return -1
    let low = (value & (mask >> shift)) << shift
    let high = value >> (53 - shift)
    return Int64(low | high)
