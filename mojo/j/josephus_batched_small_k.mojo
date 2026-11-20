from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("josephus_batched_small_k")
fn josephus_batched_small_k(values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length != 2: return -1
    let n0 = values[0]
    let k = values[1]
    if n0 < 1 or n0 > 1_000_000 or k < 1 or k > 32: return -1
    if n0 == 1: return 0
    if k == 1: return n0 - 1
    var frames = InlineArray[Int64, 1024]()
    var depth = 0
    var n = n0
    while n > 1:
        if depth == 1024: return -1
        frames[depth] = n
        depth += 1
        if n < k: n -= 1
        else: n -= n / k
    var survivor: Int64 = 0
    while depth > 0:
        depth -= 1
        let m = frames[depth]
        if m < k: survivor = (survivor + k) % m
        else:
            survivor -= m % k
            if survivor < 0: survivor += m
            else: survivor += survivor / (k - 1)
    return survivor
