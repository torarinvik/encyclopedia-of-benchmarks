from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("ternary_search")
fn ternary_search(values: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, target: Int64) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin](): return -1
    var lo=0; var hi=Int(n)
    while lo<hi:
        let third=(hi-lo)/3; let m1=lo+third; let m2=hi-third-1
        if values[m1]==target:return Int64(m1)
        if values[m2]==target:return Int64(m2)
        if target<values[m1]:hi=m1
        elif target>values[m2]:lo=m2+1
        else:lo=m1+1;hi=m2
    return -1
