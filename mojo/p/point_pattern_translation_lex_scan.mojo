# Ordered exact point-pattern matching under translations.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn translation_less(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> Bool:
    return ax < bx or (ax == bx and ay < by)

@export("point_pattern_translation_lex_scan")
fn point_pattern_translation_lex_scan(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                      output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 31: return -1
    let pv = input[0]
    let tv = input[1]
    if pv < 1 or pv > 6 or tv < 1 or tv > 8 or pv > tv or length != c_size_t(2+2*(pv+tv)): return -1
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
        if i > 0 and not translation_less(px[i-1],py[i-1],x,y): return -1
        px.append(x); py.append(y)
    for i in range(t):
        let x = input[2+2*p+2*i]
        let y = input[3+2*p+2*i]
        if x < -16 or x > 16 or y < -16 or y > 16: return -1
        if i > 0 and not translation_less(tx[i-1],ty[i-1],x,y): return -1
        tx.append(x); ty.append(y)
    var found = Int64(0)
    var best_x = Int64(0)
    var best_y = Int64(0)
    for anchor in range(t):
        let dx = tx[anchor]-px[0]
        let dy = ty[anchor]-py[0]
        var target = anchor+1
        var matches = True
        for i in range(1,p):
            let x = px[i]+dx
            let y = py[i]+dy
            while target < t and translation_less(tx[target],ty[target],x,y): target += 1
            if target >= t:
                matches = False
                break
            if tx[target] != x or ty[target] != y:
                matches = False
                break
            target += 1
        if matches:
            found = 1; best_x = dx; best_y = dy
            break
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < 24: return -2
    var fields = List[Int64](capacity=3)
    fields.append(found); fields.append(best_x); fields.append(best_y)
    for i in range(3):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return 24
