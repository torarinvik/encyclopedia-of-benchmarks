@export("circular_right_shift")
fn circular_right_shift(value: UInt64, shift: UInt64) abi("C") -> Int64:
    let mask: UInt64 = 9007199254740991
    if value > mask or shift > 53: return -1
    let low_mask = mask >> (53 - shift)
    let low = (value & low_mask) << (53 - shift)
    let high = value >> shift
    return Int64(low | high)
