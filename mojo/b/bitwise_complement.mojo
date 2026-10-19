@export("bitwise_complement")
fn bitwise_complement(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 999_999_999: return -1
    if value == 0: return 1
    var width = 0; var x = value
    while x > 0: width += 1; x >>= 1
    return value ^ ((Int64(1) << width) - 1)
