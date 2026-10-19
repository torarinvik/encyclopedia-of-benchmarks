@export("arithmetic_right_shift")
fn arithmetic_right_shift(n: UInt64, shift: UInt64) abi("C") -> Int64:
    if n > 9007199254740991 or shift > 53: return -1
    let count = UInt(shift)
    let low_mask = (UInt64(1) << UInt(53 - shift)) - 1
    var fill_mask: UInt64 = 0
    if (n >> 52) != 0: fill_mask = 9007199254740991 ^ low_mask
    return Int64(fill_mask | (n >> count))
