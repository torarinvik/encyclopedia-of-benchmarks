from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
comptime LIMBS = 4
comptime WIDTH = 128

fn greater_equal(a: InlineArray[UInt32, 5], b: InlineArray[UInt32, 5]) -> Bool:
    for step in range(5):
        let i = 4 - step
        if a[i] > b[i]: return True
        if a[i] < b[i]: return False
    return True

fn subtract(a: InlineArray[UInt32, 5], b: InlineArray[UInt32, 5]) -> InlineArray[UInt32, 5]:
    var result = a
    var borrow: Int64 = 0
    for i in range(5):
        var d = Int64(result[i]) - Int64(b[i]) - borrow
        if d < 0: d += 4294967296; borrow = 1
        else: borrow = 0
        result[i] = UInt32(d)
    return result

@export("uint128_t")
fn uint128_t(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n != c_size_t(9): return -1
    let op = v[0]
    if op < 0 or op > 1: return -1
    var dividend = InlineArray[UInt32, 4](fill=0)
    var divisor = InlineArray[UInt32, 4](fill=0)
    var nonzero = False
    for i in range(4):
        let x = v[1+i]; let y = v[1+4+i]
        if x < 0 or x > 4294967295 or y < 0 or y > 4294967295: return -1
        dividend[i] = UInt32(x); divisor[i] = UInt32(y)
        if y != 0: nonzero = True
    if not nonzero: return -1
    var rem = InlineArray[UInt32, 5](fill=0)
    var quot = InlineArray[UInt32, 4](fill=0)
    var div_ext = InlineArray[UInt32, 5](fill=0)
    for i in range(4): div_ext[i] = divisor[i]
    for step in range(WIDTH):
        let bit = WIDTH - 1 - step
        var carry: UInt32 = UInt32((dividend[bit / 32] >> (bit % 32)) & 1)
        for i in range(5):
            let next = rem[i] >> 31
            rem[i] = (rem[i] << 1) | carry
            carry = next
        if greater_equal(rem, div_ext):
            rem = subtract(rem, div_ext)
            quot[bit / 32] = quot[bit / 32] | (UInt32(1) << (bit % 32))
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(16): return -2
    for i in range(4):
        let word = quot[i] if op == 0 else rem[i]
        for b in range(4): out[i*4+b] = UInt8((word >> (b*8)) & 255)
    return 16
