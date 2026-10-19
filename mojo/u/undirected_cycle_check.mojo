from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer
@export("undirected_cycle_check")
fn undirected_cycle_check(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 2 or n > 514: return -1
    let vertices = v[0]; let edges = v[1]
    if vertices < 0 or vertices > 32 or edges < 0 or edges > 256 or n != c_size_t(2+2*edges): return -1
    var adj = InlineArray[UInt8, 1024](fill=0)
    for i in range(Int(edges)):
        let a = v[2+2*i]; let b = v[3+2*i]
        if a < 0 or a >= vertices or b < 0 or b >= vertices: return -1
        if adj[Int(a)*32+Int(b)] != 0: return -1
        adj[Int(a)*32+Int(b)] = 1; adj[Int(b)*32+Int(a)] = 1
    var seen = InlineArray[UInt8,32](fill=0)
    for root in range(Int(vertices)):
        if seen[root] != 0: continue
        var stack_v = InlineArray[Int,32](fill=0); var stack_p = InlineArray[Int,32](fill=0); var size = 1
        stack_v[0] = root; stack_p[0] = -1; seen[root] = 1
        while size > 0:
            size -= 1; let node = stack_v[size]; let parent = stack_p[size]
            for next in range(Int(vertices)):
                if adj[node*32+next] == 0: continue
                if next == node: return 1
                if seen[next] == 0:
                    seen[next] = 1; stack_v[size] = next; stack_p[size] = node; size += 1
                elif next != parent: return 1
    return 0
