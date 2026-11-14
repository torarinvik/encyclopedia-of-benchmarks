from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
from std.collections import List

@export("xor_filter_peeling")
fn xor_filter_peeling(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 259: return -1
    let nv = input[0]
    let sv = input[1]
    let qv = input[2]
    if nv < 0 or nv > 32 or sv < 3 or sv > 96 or qv < 0 or qv > 32: return -1
    let n = Int(nv)
    let slots = Int(sv)
    let q = Int(qv)
    if length != c_size_t(3+4*(n+q)): return -1
    for i in range(n+q):
        let at = 3+4*i
        let a = input[at]
        let b = input[at+1]
        let c = input[at+2]
        let f = input[at+3]
        if a < 0 or a >= sv or b < 0 or b >= sv or c < 0 or c >= sv or a == b or a == c or b == c or f < 0 or f > 255: return -1
    var degree = List[Int](capacity=96)
    var edge_xor = List[Int](capacity=96)
    var queue = List[Int](capacity=96)
    var table = List[Int](capacity=96)
    var stack_slot = List[Int](capacity=32)
    var stack_edge = List[Int](capacity=32)
    for _ in range(96):
        degree.append(0)
        edge_xor.append(0)
        queue.append(0)
        table.append(0)
    for _ in range(32):
        stack_slot.append(0)
        stack_edge.append(0)
    for edge in range(n):
        for j in range(3):
            let slot = Int(input[3+4*edge+j])
            degree[slot] += 1
            edge_xor[slot] = edge_xor[slot] ^ edge
    var head = 0
    var tail = 0
    var used = 0
    for slot in range(slots):
        if degree[slot] == 1:
            queue[tail] = slot
            tail += 1
    while head < tail:
        let slot = queue[head]
        head += 1
        if degree[slot] != 1: continue
        let edge = edge_xor[slot]
        stack_slot[used] = slot
        stack_edge[used] = edge
        used += 1
        for j in range(3):
            let v = Int(input[3+4*edge+j])
            degree[v] -= 1
            edge_xor[v] = edge_xor[v] ^ edge
            if degree[v] == 1:
                queue[tail] = v
                tail += 1
    if used != n: return -2
    while used > 0:
        used -= 1
        let at = 3+4*stack_edge[used]
        let a = Int(input[at])
        let b = Int(input[at+1])
        let c = Int(input[at+2])
        table[stack_slot[used]] = Int(input[at+3]) ^ table[a] ^ table[b] ^ table[c]
    var result: Int64 = 0
    for i in range(q):
        let at = 3+4*(n+i)
        let a = Int(input[at])
        let b = Int(input[at+1])
        let c = Int(input[at+2])
        if (table[a] ^ table[b] ^ table[c]) == Int(input[at+3]): result += Int64(i+1)
    return result
