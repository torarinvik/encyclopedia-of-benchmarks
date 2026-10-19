from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime MAX_DIGITS = 64
comptime MAX_OUT = 1664
@export("uint_convert_base")
fn uint_convert_base(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > 67: return -1
    let sb = v[0]; let tb = v[1]; let count = v[2]
    if sb < 2 or sb > 67108864 or tb < 2 or tb > 67108864 or count < 0 or count > MAX_DIGITS or n != c_size_t(3+count): return -1
    var digits = InlineArray[UInt32, 64](fill=0)
    for i in range(Int(count)):
        if v[3+i] < 0 or v[3+i] >= sb: return -1
        digits[i] = UInt32(v[3+i])
    if count > 0 and digits[Int(count)-1] == 0: return -1
    var used = Int(count)
    var result = InlineArray[UInt32, 1664](fill=0)
    var out_n = 0
    while used > 0:
        var rem: UInt64 = 0
        for step in range(used):
            let i = used - 1 - step
            let value = rem * UInt64(sb) + UInt64(digits[i])
            digits[i] = UInt32(value / UInt64(tb))
            rem = value % UInt64(tb)
        if out_n >= MAX_OUT: return -1
        result[out_n] = UInt32(rem); out_n += 1
        while used > 0 and digits[used-1] == 0: used -= 1
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(out_n*4): return -2
    for i in range(out_n):
        for b in range(4): out[i*4+b] = UInt8((result[i] >> (8*b)) & 255)
    return Int64(out_n*4)
