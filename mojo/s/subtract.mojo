from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("subtract")
fn subtract(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 4 or n > 516: return -2
    let ar=v[0]; let ac=v[1]
    if ar < 0 or ar > 16 or ac < 0 or ac > 16 or (ar == 0 and ac != 0): return -2
    let acells=Int(ar*ac)
    let bd=2+acells
    if bd+1 >= Int(n): return -2
    let br=v[bd]; let bc=v[bd+1]
    if br < 0 or br > 16 or bc < 0 or bc > 16 or (br == 0 and bc != 0): return -2
    let bcells=Int(br*bc)
    if Int(n) != bd+2+bcells: return -2
    if ar != br or ac != bc: return -1
    for i in range(acells):
        if v[2+i] < -2147483648 or v[2+i] > 2147483647: return -2
        if v[bd+2+i] < -2147483648 or v[bd+2+i] > 2147483647: return -2
    if acells == 0: return 0
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(acells*4): return -3
    var temp=InlineArray[UInt32,1024](fill=0)
    for i in range(acells):
        var difference=v[2+i]-v[bd+2+i]
        if difference<0:difference+=4294967296
        temp[i]=UInt32(difference)
    for i in range(acells):
        for b in range(4): out[i*4+b]=UInt8((temp[i] >> UInt(8*b)) & 255)
    return Int64(acells)
