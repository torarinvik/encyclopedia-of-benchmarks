from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

# Independent truth-table transformation; see the package's AFPL v5 notice.
@export("cbench_ghostscript_rop3_transform")
fn cbench_ghostscript_rop3_transform(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if length != 2 or values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    if values[0] < 0 or values[0] > 14 or values[1] < 0 or values[1] > 255: return -1
    let mode = Int(values[0])
    let code = values[1]
    var result = Int64(0)
    for index in range(8):
        let d = index & 1
        let s = (index >> 1) & 1
        let t = (index >> 2) & 1
        var source = index
        if mode <= 2:
            source ^= 1 << mode
        elif mode <= 8:
            let dimension = (mode - 3) // 2
            let mask = 1 << dimension
            source = (index & ~mask) | (((mode - 3) & 1) << dimension)
        elif mode == 9:
            source = d | (t << 1) | (s << 2)
        var bit = (code >> source) & 1
        if mode >= 10 and mode <= 13:
            var operand = s
            if mode >= 12: operand = t
            if operand == ((mode - 10) & 1): bit = Int64(d)
        elif mode == 14:
            bit = 1 - bit
        result |= bit << index
    return result
