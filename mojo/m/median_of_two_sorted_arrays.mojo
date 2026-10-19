from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("median_of_two_sorted_arrays")
fn median_of_two_sorted_arrays(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 3 or n > 1026: return -1
    let a = v[0]; let b = v[1]
    if a < 0 or b < 0 or a + b < 1 or a + b > 1024 or Int(n) != Int(a + b) + 2: return -1
    let total = Int(a + b); let bs = Int(a) + 2
    for i in range(Int(a)):
        if v[i+2] < -2147483648 or v[i+2] > 2147483647 or (i > 0 and v[i+1] > v[i+2]): return -1
    for i in range(Int(b)):
        if v[bs+i] < -2147483648 or v[bs+i] > 2147483647 or (i > 0 and v[bs+i-1] > v[bs+i]): return -1
    var merged = InlineArray[Int64, 1024](fill=0); var i=0; var j=0
    for k in range(total):
        if i < Int(a) and (j >= Int(b) or v[2+i] <= v[bs+j]): merged[k]=v[2+i]; i+=1
        else: merged[k]=v[bs+j]; j+=1
    if total % 2 == 1: return merged[total//2] * 2
    return merged[total//2-1] + merged[total//2]
