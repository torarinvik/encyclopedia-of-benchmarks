from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn put_word(buf: InlineArray[Int64, 144], at: Int, value: Int64) -> InlineArray[Int64, 144]:
    var b = buf
    b[at] = value
    return b

@export("undirected_adjacency_list_graph")
fn undirected_adjacency_list_graph(v: UnsafePointer[Int64, ImmutAnyOrigin], n: c_size_t, out: UnsafePointer[UInt8, MutAnyOrigin], cap: c_size_t) abi("C") -> Int64:
    if v == UnsafePointer[Int64, ImmutAnyOrigin]() or n < 1 or n > 97: return -1
    let q = v[0]
    if q < 0 or q > 24 or n != c_size_t(1+4*q): return -1
    var adj = InlineArray[UInt8,64](fill=0)
    var weights = InlineArray[Int64,64](fill=0)
    var nodes = 0; var cursor = 1
    var response = InlineArray[Int64,144](fill=0); var used = 0
    for op_index in range(Int(q)):
        let op=v[cursor]; let a=v[cursor+1]; let b=v[cursor+2]; let c=v[cursor+3]; cursor += 4
        if op < 0 or op > 4: return -1
        response[used] = op; used += 1
        if op == 0:
            if a != 0 or b != 0 or c != 0 or nodes >= 8: return -1
            response[used] = 1; response[used+1] = Int64(nodes); used += 2; nodes += 1
        elif op == 1:
            if a < -2147483648 or a > 2147483647 or b < -2147483648 or b > 2147483647 or c < -2147483648 or c > 2147483647: return -1
            let ok = a >= 0 and a < nodes and b >= 0 and b < nodes and adj[Int(a)*8+Int(b)] == 0
            if ok:
                adj[Int(a)*8+Int(b)] = 1; adj[Int(b)*8+Int(a)] = 1
                weights[Int(a)*8+Int(b)] = c; weights[Int(b)*8+Int(a)] = c
            response[used] = 1; response[used+1] = 1 if ok else 0; used += 2
        elif op == 2:
            if b != 0 or c != 0 or a < 0 or a >= nodes: return -1
            var count = 0
            for j in range(nodes): if adj[Int(a)*8+j] != 0: count += 1
            response[used] = Int64(count + 1); used += 1
            response[used] = Int64(count); used += 1
            for j in range(nodes):
                if adj[Int(a)*8+j] != 0: response[used] = Int64(j); used += 1
        elif op == 3:
            if c != 0 or a < 0 or a >= nodes or b < -2147483648 or b > 2147483647: return -1
            let present = adj[Int(a)*8+Int(b)] != 0 if b >= 0 and b < nodes else False
            response[used] = 2; response[used+1] = 1 if present else 0
            response[used+2] = weights[Int(a)*8+Int(b)] if present else 0; used += 3
        else:
            if a != 0 or b != 0 or c != 0: return -1
            response[used] = 1; response[used+1] = Int64(nodes); used += 2
    let byte_count = used * 8
    if out == UnsafePointer[UInt8, MutAnyOrigin]() or cap < c_size_t(byte_count): return -2
    for i in range(used):
        for b in range(8): out[i*8+b] = UInt8((response[i] >> (b*8)) & 255)
    return Int64(byte_count)
