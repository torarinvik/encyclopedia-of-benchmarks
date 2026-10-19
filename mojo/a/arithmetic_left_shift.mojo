@export("arithmetic_left_shift")
fn arithmetic_left_shift(n: UInt64, shift: UInt64) abi("C") -> Int64:
    if n > 9007199254740991 or shift > 53:
        return -1
    return Int64((n << UInt(shift)) & 9007199254740991)
