from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import InlineArray

@export("matrix_chain_multiplication")
fn matrix_chain_multiplication(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if n > 65 or (n > 0 and v == UnsafePointer[Int64, ImmutAnyOrigin]()): return -1
    for i in range(Int(n)):
        if v[i] < 1 or v[i] > 1000: return -1
    if n < 2: return 0
    let count = Int(n) - 1
    var costs = InlineArray[Int64, 4225](fill=0)
    for chain in range(2, count + 1):
        for start in range(count - chain + 1):
            let end = start + chain - 1
            var best: Int64 = 0x7fffffffffffffff
            for split in range(start, end):
                let cost = costs[start*65+split] + costs[(split+1)*65+end] + v[start]*v[split+1]*v[end+1]
                if cost < best: best = cost
            costs[start*65+end] = best
    return costs[(count-1)*65+(count-1)]
