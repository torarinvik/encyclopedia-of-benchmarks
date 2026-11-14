from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn edge_connected(input: UnsafePointer[Int64, ImmutAnyOrigin], n: Int, m: Int, active: UInt64) -> Bool:
    for skip in range(-1, m):
        if skip >= 0 and (active & (UInt64(1) << skip)) == 0: continue
        var visited = 1
        var queue = InlineArray[Int, 8](fill=0)
        var head = 0
        var tail = 1
        while head < tail:
            let node = queue[head]
            head += 1
            for edge in range(m):
                if edge != skip and (active & (UInt64(1) << edge)) != 0:
                    let u = Int(input[2 + 2 * edge]); let v = Int(input[3 + 2 * edge])
                    var neighbor = n
                    if u == node: neighbor = v
                    elif v == node: neighbor = u
                    if neighbor < n and (visited & (1 << neighbor)) == 0:
                        visited |= 1 << neighbor
                        queue[tail] = neighbor
                        tail += 1
        if visited != (1 << n) - 1: return False
    return True

fn edge_store(output: UnsafePointer[UInt8, MutAnyOrigin], slot: Int, value: Int64):
    var bits = UInt64(value)
    for byte in range(8):
        output[8 * slot + byte] = UInt8(bits & 255)
        bits >>= 8

@export("two_edge_connected_spanning_subgraph_greedy")
fn two_edge_connected_spanning_subgraph_greedy(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t, output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 59: return -1
    let nv = input[0]; let mv = input[1]
    if nv < 3 or nv > 8 or mv < 3 or mv > 28 or length != c_size_t(2 + 2 * mv): return -1
    let n = Int(nv); let m = Int(mv)
    var seen = InlineArray[Bool, 64](fill=False)
    for e in range(m):
        let u = input[2 + 2 * e]; let v = input[3 + 2 * e]
        if u < 0 or u >= v or v >= nv: return -1
        let index = 8 * Int(u) + Int(v)
        if seen[index]: return -1
        seen[index] = True
    var active = (UInt64(1) << m) - 1
    if not edge_connected(input, n, m, active): return -1
    for e in range(m):
        let trial = active & ~(UInt64(1) << e)
        if edge_connected(input, n, m, trial): active = trial
    var count = 0
    for e in range(m):
        if (active & (UInt64(1) << e)) != 0: count += 1
    let bytes = 8 * (1 + 2 * count)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    edge_store(output, 0, Int64(count))
    var slot = 1
    for u in range(n):
        for v in range(u + 1, n):
            for e in range(m):
                if (active & (UInt64(1) << e)) != 0 and input[2 + 2 * e] == Int64(u) and input[3 + 2 * e] == Int64(v):
                    edge_store(output, slot, Int64(u))
                    edge_store(output, slot + 1, Int64(v))
                    slot += 2
    return Int64(bytes)
