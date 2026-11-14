from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn delaunay_orientation(x: List[Int64], y: List[Int64], a: Int, b: Int, c: Int) -> Int64:
    return (x[b]-x[a])*(y[c]-y[a])-(y[b]-y[a])*(x[c]-x[a])

fn delaunay_circle(x: List[Int64], y: List[Int64], a: Int, b: Int, c: Int, d: Int) -> Int64:
    let ax = x[a]-x[d]; let ay = y[a]-y[d]
    let bx = x[b]-x[d]; let by = y[b]-y[d]
    let cx = x[c]-x[d]; let cy = y[c]-y[d]
    let aa = ax*ax+ay*ay; let bb = bx*bx+by*by; let cc = cx*cx+cy*cy
    return aa*(bx*cy-by*cx)-bb*(ax*cy-ay*cx)+cc*(ax*by-ay*bx)

@export("voronoi_delaunay_empty_circle")
fn voronoi_delaunay_empty_circle(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 17: return -1
    let nv = input[0]
    if nv < 3 or nv > 8: return -1
    let n = Int(nv)
    if length != c_size_t(1+2*n): return -1
    var x = List[Int64](capacity=n)
    var y = List[Int64](capacity=n)
    for i in range(n):
        let px = input[1+2*i]; let py = input[2+2*i]
        if px < -50 or px > 50 or py < -50 or py > 50: return -1
        for j in range(i):
            if x[j] == px and y[j] == py: return -1
        x.append(px); y.append(py)
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if delaunay_orientation(x,y,a,b,c) == 0: return -1
                for d in range(c+1,n):
                    if delaunay_circle(x,y,a,b,c,d) == 0: return -1
    var edges = List[Int](capacity=n)
    for _ in range(n): edges.append(0)
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                let orientation = delaunay_orientation(x,y,a,b,c)
                var empty = True
                for d in range(n):
                    if d == a or d == b or d == c: continue
                    let determinant = delaunay_circle(x,y,a,b,c,d)
                    if (orientation > 0 and determinant > 0) or (orientation < 0 and determinant < 0):
                        empty = False
                        break
                if empty:
                    edges[a] |= (1 << b) | (1 << c)
                    edges[b] |= 1 << c
    var fields = List[Int64](capacity=37)
    fields.append(0)
    var count = Int64(0)
    for a in range(n):
        for b in range(a+1,n):
            if (edges[a] & (1 << b)) != 0:
                fields.append(Int64(a)); fields.append(Int64(b)); count += 1
    fields[0] = count
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return Int64(bytes)
