from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn chord_between(ids: InlineArray[Int, 16], ring: Int, left: Int, item: Int, right: Int) -> Bool:
    let distance = (ids[item]-ids[left]+ring) % ring
    let span = (ids[right]-ids[left]+ring) % ring
    return distance > 0 and (span == 0 or distance < span)

@export("chord_stabilization_trace")
fn chord_stabilization_trace(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 6 or length > 115: return -1
    if input[0] < 1 or input[0] > 6 or input[1] < 1 or input[1] > 16 or input[2] < 0 or input[2] > 64: return -1
    let ring = 1 << Int(input[0])
    let n = Int(input[1])
    let q = Int(input[2])
    if n > ring or length != c_size_t(3+3*n+q): return -1
    var ids = InlineArray[Int, 16](fill=0)
    var succ = InlineArray[Int, 16](fill=0)
    var pred = InlineArray[Int, 16](fill=0)
    for i in range(n):
        if input[3+i] < 0 or input[3+i] >= Int64(ring): return -1
        if i > 0 and input[3+i] <= Int64(ids[i-1]): return -1
        if input[3+n+i] < 0 or input[3+n+i] >= Int64(n) or input[3+2*n+i] < -1 or input[3+2*n+i] >= Int64(n): return -1
        ids[i] = Int(input[3+i])
        succ[i] = Int(input[3+n+i])
        pred[i] = Int(input[3+2*n+i])
    for i in range(q):
        if input[3+3*n+i] < 0 or input[3+3*n+i] >= Int64(n): return -1
    for i in range(q):
        let node = Int(input[3+3*n+i])
        let candidate = pred[succ[node]]
        if candidate >= 0 and chord_between(ids, ring, node, candidate, succ[node]): succ[node] = candidate
        let receiver = succ[node]
        if pred[receiver] < 0 or chord_between(ids, ring, pred[receiver], node, receiver): pred[receiver] = node
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(2*n): return -2
    for i in range(n):
        output[i] = UInt8(succ[i])
        output[n+i] = UInt8(255 if pred[i] < 0 else pred[i])
    return Int64(2*n)
