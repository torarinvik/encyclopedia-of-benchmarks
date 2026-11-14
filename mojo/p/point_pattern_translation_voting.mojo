# Translation voting for exact and largest-common point-set matching.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("point_pattern_translation_voting")
fn point_pattern_translation_voting(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 31: return -1
    let pv = input[0]
    let tv = input[1]
    if pv < 1 or pv > 6 or tv < 1 or tv > 8 or length != c_size_t(2+2*(pv+tv)): return -1
    let p = Int(pv)
    let t = Int(tv)
    var px = List[Int64](capacity=p)
    var py = List[Int64](capacity=p)
    var tx = List[Int64](capacity=t)
    var ty = List[Int64](capacity=t)
    for i in range(p):
        let x = input[2+2*i]
        let y = input[3+2*i]
        if x < -16 or x > 16 or y < -16 or y > 16: return -1
        for j in range(i):
            if px[j] == x and py[j] == y: return -1
        px.append(x); py.append(y)
    for i in range(t):
        let x = input[2+2*p+2*i]
        let y = input[3+2*p+2*i]
        if x < -16 or x > 16 or y < -16 or y > 16: return -1
        for j in range(i):
            if tx[j] == x and ty[j] == y: return -1
        tx.append(x); ty.append(y)
    var dx = List[Int64](capacity=p*t)
    var dy = List[Int64](capacity=p*t)
    for i in range(p):
        for j in range(t):
            dx.append(tx[j]-px[i]); dy.append(ty[j]-py[i])
    for i in range(1,p*t):
        let x = dx[i]
        let y = dy[i]
        var j = i
        while j > 0 and (dx[j-1] > x or (dx[j-1] == x and dy[j-1] > y)):
            dx[j] = dx[j-1]; dy[j] = dy[j-1]
            j -= 1
        dx[j] = x; dy[j] = y
    var best = 0
    var best_x = Int64(0)
    var best_y = Int64(0)
    var start = 0
    while start < p*t:
        var end = start+1
        while end < p*t and dx[end] == dx[start] and dy[end] == dy[start]: end += 1
        if end-start > best:
            best = end-start; best_x = dx[start]; best_y = dy[start]
        start = end
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    var fields = List[Int64](capacity=3)
    fields.append(Int64(best)); fields.append(best_x); fields.append(best_y)
    for i in range(3):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return 24
