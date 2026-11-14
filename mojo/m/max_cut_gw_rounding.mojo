# Supplied-hyperplane Goemans-Williamson rounding profile.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("max_cut_gw_rounding")
fn max_cut_gw_rounding(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 431: return -1
    let nv = input[0]
    let mv = input[1]
    let dv = input[2]
    if nv < 2 or nv > 16 or mv < 0 or mv > 120 or dv < 1 or dv > 4 or length != c_size_t(3+3*mv+nv*dv+dv): return -1
    let n = Int(nv)
    let m = Int(mv)
    let d = Int(dv)
    var edge_u = List[Int](capacity=m)
    var edge_v = List[Int](capacity=m)
    var weights = List[Int64](capacity=m)
    var previous_u = Int64(-1)
    var previous_v = Int64(-1)
    for i in range(m):
        let u = input[3+3*i]
        let v = input[4+3*i]
        let weight = input[5+3*i]
        if u < 0 or v <= u or v >= nv or weight < 1 or weight > 10000 or u < previous_u or (u == previous_u and v <= previous_v): return -1
        previous_u = u
        previous_v = v
        edge_u.append(Int(u))
        edge_v.append(Int(v))
        weights.append(weight)
    let offset = 3+3*m
    var vectors = List[Int64](capacity=n*d)
    var normal = List[Int64](capacity=d)
    var common_norm = Int64(0)
    for vertex in range(n):
        var norm = Int64(0)
        for axis in range(d):
            let coordinate = input[offset+vertex*d+axis]
            if coordinate < -100 or coordinate > 100: return -1
            vectors.append(coordinate)
            norm += coordinate*coordinate
        if vertex == 0: common_norm = norm
        elif norm != common_norm: return -1
    if common_norm == 0: return -1
    var normal_nonzero = False
    for axis in range(d):
        let coordinate = input[offset+n*d+axis]
        if coordinate < -100 or coordinate > 100: return -1
        if coordinate != 0: normal_nonzero = True
        normal.append(coordinate)
    if not normal_nonzero: return -1
    var sides = List[Int64](capacity=n)
    for vertex in range(n):
        var dot = Int64(0)
        for axis in range(d): dot += vectors[vertex*d+axis]*normal[axis]
        if dot > 0: sides.append(1)
        else: sides.append(0)
    var cut = Int64(0)
    for i in range(m):
        if sides[edge_u[i]] != sides[edge_v[i]]: cut += weights[i]
    let bytes = 8*(n+1)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for byte in range(8): output[byte] = UInt8((cut >> (8*byte)) & 255)
    for i in range(n):
        for byte in range(8): output[8*(i+1)+byte] = UInt8((sides[i] >> (8*byte)) & 255)
    return Int64(bytes)
