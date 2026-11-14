# Bounded Streaming-Triangles replay with explicit random tape.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn stream_wedge(a: Int, b: Int, c: Int, d: Int) -> Int:
    var shared = -1
    if a == c or a == d: shared = a
    if b == c or b == d: shared = b
    if shared < 0: return -1
    var x = a
    var y = c
    if x == shared: x = b
    if y == shared: y = d
    if x == y: return -1
    if x > y:
        let temp = x
        x = y
        y = temp
    return 8*x+y

fn stream_power(base: Int64, exponent: Int) -> Int64:
    var result = Int64(1)
    for _ in range(exponent): result *= base
    return result

@export("streaming_triangles")
fn streaming_triangles(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 10 or length > 340: return -1
    let nv = input[0]; let mv = input[1]; let sev = input[2]; let swv = input[3]
    if nv < 2 or nv > 8 or mv < 1 or mv > 28 or sev < 2 or sev > 4 or swv < 1 or swv > 4: return -1
    let n = Int(nv); let m = Int(mv); let se = Int(sev); let sw = Int(swv)
    let stride = 2+2*sw
    if length != c_size_t(4+2*m+m*stride): return -1
    var us = List[Int](capacity=m)
    var vs = List[Int](capacity=m)
    var adjacency = List[Int](capacity=n)
    for _ in range(n): adjacency.append(0)
    for i in range(m):
        let u = input[4+2*i]; let v = input[5+2*i]
        if u < 0 or v <= u or v >= nv: return -1
        let a = Int(u); let b = Int(v)
        if (adjacency[a] & (1 << b)) != 0: return -1
        adjacency[a] |= 1 << b; adjacency[b] |= 1 << a
        us.append(a); vs.append(b)
    var reservoir = List[Int](capacity=se)
    var wedges = List[Int](capacity=sw)
    var closed = List[Bool](capacity=sw)
    for _ in range(se): reservoir.append(-1)
    for _ in range(sw): wedges.append(-1); closed.append(False)
    var total = Int64(0)
    var fields = List[Int64](capacity=3*m)
    let tape = 4+2*m
    for ti in range(m):
        let t = ti+1
        let edge_key = 8*us[ti]+vs[ti]
        for s in range(sw):
            if wedges[s] == edge_key: closed[s] = True
        let rec = tape+ti*stride
        let draw = input[rec]; let slot_value = input[rec+1]
        let limit = stream_power(Int64(t),se)
        let threshold = limit-stream_power(Int64(t-1),se)
        if draw < 0 or draw >= limit: return -1
        var fresh = List[Int](capacity=se)
        var removed = 0
        if draw < threshold:
            if slot_value < 0 or slot_value >= sev: return -1
            let slot = Int(slot_value)
            let old = reservoir[slot]
            if old >= 0:
                for j in range(se):
                    let other = reservoir[j]
                    if j != slot and other >= 0 and stream_wedge(us[old],vs[old],us[other],vs[other]) >= 0: removed += 1
            reservoir[slot] = ti
            for j in range(se):
                let other = reservoir[j]
                if j != slot and other >= 0:
                    let wedge = stream_wedge(us[ti],vs[ti],us[other],vs[other])
                    if wedge >= 0: fresh.append(wedge)
        elif slot_value != 0: return -1
        total += Int64(len(fresh)-removed)
        if total < 0: return -1
        for s in range(sw):
            let wedge_draw = input[rec+2+2*s]
            let pick = input[rec+3+2*s]
            if len(fresh) > 0:
                if wedge_draw < 0 or wedge_draw >= total: return -1
                if wedge_draw < Int64(len(fresh)):
                    if pick < 0 or pick >= Int64(len(fresh)): return -1
                    wedges[s] = fresh[Int(pick)]
                    closed[s] = False
                elif pick != 0: return -1
            elif wedge_draw != 0 or pick != 0: return -1
        var hits = Int64(0)
        for s in range(sw):
            if closed[s]: hits += 1
        fields.append(total)
        fields.append(3*hits*1000000 // Int64(sw))
        fields.append(hits*Int64(t)*Int64(t)*total*1000000 // Int64(sw*se*(se-1)))
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
