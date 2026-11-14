from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("tsvc_s272_threshold_dual_accumulate")
fn tsvc_s272_threshold_dual_accumulate(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 8 or length > 323: return -1
    let n0 = input[0]; let passes = input[1]; let threshold = input[2]
    if n0 < 1 or n0 > 64 or passes < 1 or passes > 8 or threshold < -2 or threshold > 2 or length != c_size_t(3 + 5 * n0): return -1
    let n = Int(n0)
    for i in range(3, 3 + 5 * n):
        if input[i] < -2 or input[i] > 2: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(16 * n): return -2
    var a = List[Int64](length=n, fill=0)
    var b = List[Int64](length=n, fill=0)
    for i in range(n): a[i] = input[3 + i]; b[i] = input[3 + n + i]
    for _ in range(Int(passes)):
        for i in range(n):
            if input[3 + 4 * n + i] >= threshold:
                let c = input[3 + 2 * n + i]
                a[i] += c * input[3 + 3 * n + i]
                b[i] += c * c
    for i in range(n):
        for byte in range(8):
            output[8 * i + byte] = UInt8((a[i] >> (8 * byte)) & 255)
            output[8 * (n + i) + byte] = UInt8((b[i] >> (8 * byte)) & 255)
    return Int64(2 * n)
