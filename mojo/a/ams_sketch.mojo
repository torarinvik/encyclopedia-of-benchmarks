from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer
from std.collections import List

@export("ams_sketch")
fn ams_sketch(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
              output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 116: return -1
    let dv = input[0]
    let wv = input[1]
    let kv = input[2]
    let uv = input[3]
    if (dv != 1 and dv != 3 and dv != 5) or wv < 1 or wv > 8 or kv < 1 or kv > 8 or uv < 0 or uv > 16: return -1
    let depth = Int(dv)
    let width = Int(wv)
    let keys = Int(kv)
    let updates = Int(uv)
    let start = 4+2*depth*keys
    if length != c_size_t(start+2*updates): return -1
    for row in range(depth):
        for key in range(keys):
            let pos = 4+2*(row*keys+key)
            if input[pos] < 0 or input[pos] >= wv or (input[pos+1] != -1 and input[pos+1] != 1): return -1
    for i in range(updates):
        let key = input[start+2*i]
        let weight = input[start+2*i+1]
        if key < 0 or key >= kv or weight < -1000 or weight > 1000: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 8: return -2
    var counters = List[Int64](capacity=40)
    var estimates = List[Int64](capacity=5)
    for _ in range(40): counters.append(0)
    for _ in range(5): estimates.append(0)
    for i in range(updates):
        let key = Int(input[start+2*i])
        let weight = input[start+2*i+1]
        for row in range(depth):
            let pos = 4+2*(row*keys+key)
            let bucket = Int(input[pos])
            counters[row*8+bucket] += weight*input[pos+1]
    for row in range(depth):
        for bucket in range(width):
            let count = counters[row*8+bucket]
            estimates[row] += count*count
    for i in range(1, depth):
        let estimate = estimates[i]
        var j = i
        while j > 0 and estimates[j-1] > estimate:
            estimates[j] = estimates[j-1]
            j -= 1
        estimates[j] = estimate
    var bits = bitcast[UInt64](estimates[depth//2])
    for j in range(8):
        output[j] = UInt8(bits & UInt64(255))
        bits = bits >> 8
    return 8
