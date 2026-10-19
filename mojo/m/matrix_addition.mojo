from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import InlineArray

fn matrix_add_store(out: UnsafePointer[UInt8, MutAnyOrigin], pos: Int, value: UInt32):
    for b in range(4): out[pos+b] = UInt8((value >> UInt32(8*b)) & 255)

@export("matrix_addition")
fn matrix_addition(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 4: return -2
    if v[0] < 0 or v[0] > 16 or v[1] < 0 or v[1] > 16: return -2
    let ra = Int(v[0]); let ca = Int(v[1])
    if ra == 0 and ca != 0: return -2
    let cells = ra * ca; let bdim = 2 + cells
    if bdim + 2 > Int(n) or v[bdim] < 0 or v[bdim] > 16 or v[bdim+1] < 0 or v[bdim+1] > 16: return -2
    let rb = Int(v[bdim]); let cb = Int(v[bdim+1])
    if rb == 0 and cb != 0: return -2
    if Int(n) != bdim + 2 + rb*cb: return -2
    if ra != rb or ca != cb: return -1
    for i in range(cells):
        if v[2+i] < -2147483648 or v[2+i] > 2147483647 or v[bdim+2+i] < -2147483648 or v[bdim+2+i] > 2147483647: return -2
    if cap < c_size_t(cells*4) or (cells > 0 and out == UnsafePointer[UInt8, MutAnyOrigin]()): return -3
    var sums = InlineArray[UInt32, 256](fill=0)
    for i in range(cells): sums[i] = UInt32(Int32(v[2+i])) + UInt32(Int32(v[bdim+2+i]))
    for i in range(cells): matrix_add_store(out, i*4, sums[i])
    return Int64(cells)
