from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("fifocache")
fn fifocache(a: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if a == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 26: return -1
    let capacity = a[0]
    let ops = a[1]
    if capacity < 1 or capacity > 6 or ops < 0 or ops > 8 or n != 2 + 3 * ops: return -1
    var keys = InlineArray[Int64, 6](0)
    var vals = InlineArray[Int64, 6](0)
    var query = InlineArray[UInt8, 8](0)
    var size: Int64 = 0
    var hits: Int64 = 0
    var misses: Int64 = 0
    var gets: Int64 = 0
    for i in range(ops):
        let op = a[2 + 3 * i]
        let key = a[3 + 3 * i]
        let value = a[4 + 3 * i]
        if key < 0 or key > 15 or (op != 0 and op != 1): return -1
        if op == 0:
            if value < 0 or value > 255: return -1
            var j: Int64 = 0
            while j < size and keys[j] != key: j += 1
            if j < size:
                for k in range(j + 1, size):
                    keys[k - 1] = keys[k]
                    vals[k - 1] = vals[k]
                size -= 1
            if size == capacity:
                for k in range(1, size):
                    keys[k - 1] = keys[k]
                    vals[k - 1] = vals[k]
                size -= 1
            keys[size] = key
            vals[size] = value
            size += 1
        else:
            if value != 0: return -1
            var j: Int64 = 0
            while j < size and keys[j] != key: j += 1
            if j < size:
                hits += 1
                query[gets] = UInt8(vals[j])
            else:
                misses += 1
                query[gets] = 255
            gets += 1
    let bytes = 4 + gets + 2 * size
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < bytes: return -2
    var stage = InlineArray[UInt8, 26](0)
    stage[0] = UInt8(hits)
    stage[1] = UInt8(misses)
    stage[2] = UInt8(size)
    stage[3] = UInt8(gets)
    for i in range(gets): stage[4 + i] = query[i]
    for i in range(size):
        stage[4 + gets + 2 * i] = UInt8(keys[i])
        stage[5 + gets + 2 * i] = UInt8(vals[i])
    for i in range(bytes): out[i] = stage[i]
    return bytes
