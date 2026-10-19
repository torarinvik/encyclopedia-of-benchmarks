from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("matrix_equalization")
fn matrix_equalization(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 66: return -1
    let length = Int(n) - 1; let step = v[0]
    if step < 1 or step > length: return -1
    var minimum = length
    for target in range(length):
        var seen = False
        for previous in range(target):
            if v[previous+1] == v[target+1]: seen = True
        if seen: continue
        var updates = 0; var index = 0
        while index < length:
            if v[index+1] == v[target+1]: index += 1
            else: updates += 1; index += Int(step)
        if updates < minimum: minimum = updates
    return Int64(minimum)
