# Independently authored draft; not compiled or run.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn mec_distance(circle: InlineArray[Int64,4], x: Int64, y: Int64) -> Int64:
    let dx = x*circle[2]-circle[0]
    let dy = y*circle[2]-circle[1]
    return dx*dx+dy*dy

fn mec_point(x: Int64, y: Int64) -> InlineArray[Int64,4]:
    var circle = InlineArray[Int64,4](fill=0)
    circle[0] = x; circle[1] = y; circle[2] = 1
    return circle

fn mec_pair(ax: Int64, ay: Int64, bx: Int64, by: Int64) -> InlineArray[Int64,4]:
    var circle = InlineArray[Int64,4](fill=0)
    circle[0] = ax+bx; circle[1] = ay+by; circle[2] = 2
    circle[3] = mec_distance(circle,ax,ay)
    return circle

fn mec_triple(ax: Int64, ay: Int64, bx: Int64, by: Int64, cx: Int64, cy: Int64) -> InlineArray[Int64,4]:
    var den = 2*(ax*(by-cy)+bx*(cy-ay)+cx*(ay-by))
    if den == 0:
        let ab = mec_pair(ax,ay,bx,by)
        let ac = mec_pair(ax,ay,cx,cy)
        let bc = mec_pair(bx,by,cx,cy)
        if ab[3] >= ac[3] and ab[3] >= bc[3]: return ab
        if ac[3] >= bc[3]: return ac
        return bc
    let aa = ax*ax+ay*ay; let bb = bx*bx+by*by; let cc = cx*cx+cy*cy
    var x = aa*(by-cy)+bb*(cy-ay)+cc*(ay-by)
    var y = aa*(cx-bx)+bb*(ax-cx)+cc*(bx-ax)
    if den < 0:
        den = -den; x = -x; y = -y
    var circle = InlineArray[Int64,4](fill=0)
    circle[0] = x; circle[1] = y; circle[2] = den
    circle[3] = mec_distance(circle,ax,ay)
    return circle

@export("minimum_enclosing_circle_incremental_boundary")
fn minimum_enclosing_circle_incremental_boundary(input: UnsafePointer[Int64,ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8,MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64,ImmutAnyOrigin]() or length < 4 or length > 194: return -1
    if input[0] < 1 or input[0] > 64: return -1
    let n = Int(input[0])
    if length != c_size_t(1+3*n): return -1
    var xs = InlineArray[Int64,64](fill=0)
    var ys = InlineArray[Int64,64](fill=0)
    var order = InlineArray[Int,64](fill=0)
    var seen = InlineArray[Bool,64](fill=False)
    for i in range(n):
        let x = input[1+2*i]; let y = input[2+2*i]
        if x < -100 or x > 100 or y < -100 or y > 100: return -1
        xs[i] = x; ys[i] = y
    for i in range(n):
        let v = input[1+2*n+i]
        if v < 0 or v >= Int64(n): return -1
        if seen[Int(v)]: return -1
        seen[Int(v)] = True; order[i] = Int(v)
    if output == UnsafePointer[UInt8,MutAnyOrigin]() or capacity < c_size_t(n): return -2
    let first = order[0]
    var circle = mec_point(xs[first],ys[first])
    for i in range(1,n):
        let a = order[i]
        if mec_distance(circle,xs[a],ys[a]) <= circle[3]: continue
        circle = mec_point(xs[a],ys[a])
        for j in range(i):
            let b = order[j]
            if mec_distance(circle,xs[b],ys[b]) <= circle[3]: continue
            circle = mec_pair(xs[a],ys[a],xs[b],ys[b])
            for k in range(j):
                let c = order[k]
                if mec_distance(circle,xs[c],ys[c]) > circle[3]:
                    circle = mec_triple(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])
    for i in range(n):
        if mec_distance(circle,xs[i],ys[i]) == circle[3]: output[i] = 1
        else: output[i] = 0
    return Int64(n)
