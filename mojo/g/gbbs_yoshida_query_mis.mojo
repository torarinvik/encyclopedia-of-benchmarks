# Bounded Yoshida MIS query; see the package's upstream notices.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn yoshida_hash(value: UInt64) -> UInt64:
    var x = value * UInt64(3935559000370003845) + UInt64(2691343689449507681)
    x = x ^ (x >> 21)
    x = x ^ (x << 37)
    x = x ^ (x >> 4)
    x = x * UInt64(4768777513237032717)
    x = x ^ (x << 20)
    x = x ^ (x >> 41)
    x = x ^ (x << 5)
    return x

fn yoshida_query(vertex: Int, degrees: InlineArray[Int, 12], neighbors: InlineArray[Int, 144],
                 priority: InlineArray[UInt64, 12], inout work: Int, cutoff: Int) -> Int64:
    for i in range(degrees[vertex]):
        if work == cutoff: return -1
        let neighbor = neighbors[vertex * 12 + i]
        work += 1
        if priority[vertex] < priority[neighbor] or (priority[vertex] == priority[neighbor] and vertex <= neighbor):
            break
        let status = yoshida_query(neighbor, degrees, neighbors, priority, work, cutoff)
        if status == 1: return 0
        if status == -1: return -1
    return 1

@export("gbbs_yoshida_query_mis")
fn gbbs_yoshida_query_mis(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                           output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 52: return -1
    let nv = input[0]
    let mv = input[1]
    let root = input[2]
    let cutoff = input[3]
    if nv < 1 or nv > 12 or mv < 0 or mv > 24 or root < 0 or root >= nv or cutoff < 0 or cutoff > 128:
        return -1
    if Int(length) != 4 + 2 * Int(mv): return -1
    let n = Int(nv)
    var edges = InlineArray[Bool, 144](fill=False)
    var degrees = InlineArray[Int, 12](fill=0)
    for i in range(Int(mv)):
        let u = input[4 + 2 * i]
        let v = input[5 + 2 * i]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u)
        let b = Int(v)
        if edges[a * 12 + b]: return -1
        edges[a * 12 + b] = True
        edges[b * 12 + a] = True
        degrees[a] += 1
        degrees[b] += 1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 16: return -2
    var priority = InlineArray[UInt64, 12](fill=0)
    var neighbors = InlineArray[Int, 144](fill=0)
    for i in range(n): priority[i] = yoshida_hash(UInt64(i))
    for vertex in range(n):
        var count = 0
        for other in range(n):
            if edges[vertex * 12 + other]:
                var index = count
                while index > 0:
                    let previous = neighbors[vertex * 12 + index - 1]
                    if priority[previous] < priority[other] or (priority[previous] == priority[other] and previous < other):
                        break
                    neighbors[vertex * 12 + index] = previous
                    index -= 1
                neighbors[vertex * 12 + index] = other
                count += 1
    var work = 0
    let status = yoshida_query(Int(root), degrees, neighbors, priority, work, Int(cutoff))
    for byte in range(8):
        output[byte] = UInt8((status >> (8 * byte)) & 255)
        output[8 + byte] = UInt8((Int64(work) >> (8 * byte)) & 255)
    return 16
