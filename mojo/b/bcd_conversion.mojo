@export("bcd_conversion")
fn bcd_conversion(value: Int64) abi("C") -> Int64:
    if value < 0 or value > 9999: return -1
    var remaining = value
    var shift = 0
    var packed: Int64 = 0
    while remaining > 0:
        packed |= (remaining % 10) << shift
        remaining /= 10
        shift += 4
    return packed
