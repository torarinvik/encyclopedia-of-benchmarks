from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn rpl_floor_div(a: Int64, b: Int64) -> Int64:
    let q = a // b
    let r = a % b
    return q - (1 if r < 0 else 0)

fn rpl_ceil_div(a: Int64, b: Int64) -> Int64:
    return -rpl_floor_div(-a, b)

fn rpl_floor_sum(n: Int64, m: Int64, a: Int64, b: Int64) -> Int64:
    let aq = rpl_floor_div(a, m)
    let bq = rpl_floor_div(b, m)
    var answer = aq*n*(n-1)//2 + bq*n
    var aa = a-aq*m
    var bb = b-bq*m
    var nn = n
    var mm = m
    while True:
        if aa >= mm:
            answer += (nn-1)*nn*(aa//mm)//2
            aa %= mm
        if bb >= mm:
            answer += nn*(bb//mm)
            bb %= mm
        let top = aa*nn+bb
        if top < mm:
            return answer
        nn = top//mm
        bb = top%mm
        let t = mm
        mm = aa
        aa = t
    return answer

fn rpl_edge_chunk(scale: Int64, ax: Int64, ay: Int64, dx: Int64, dy: Int64,
                  start: Int64, columns: Int64) -> Int64:
    if columns <= 0:
        return 0
    var aa = dy*scale
    var bb = ay*dx-dy*ax
    var den = scale*dx
    if den < 0:
        aa = -aa
        bb = -bb
        den = -den
    let base = aa*start+bb
    if dx > 0:
        return -rpl_floor_sum(columns,den,aa,base)
    return -rpl_floor_sum(columns,den,-aa,-base)-columns

fn rpl_inside(xs: InlineArray[Int64,8], ys: InlineArray[Int64,8], n: Int,
              scale: Int64, x: Int64, y: Int64) -> Bool:
    let px = x*scale
    let py = y*scale
    var inside = False
    for i in range(n):
        let j = (i+1)%n
        let cross = (xs[j]-xs[i])*(py-ys[i])-(ys[j]-ys[i])*(px-xs[i])
        if cross == 0 and px >= min(xs[i],xs[j]) and px <= max(xs[i],xs[j]) and py >= min(ys[i],ys[j]) and py <= max(ys[i],ys[j]):
            return False
        if (ys[i] > py) != (ys[j] > py):
            let dy = ys[j]-ys[i]
            let dx = xs[j]-xs[i]
            let left = xs[i]*dy+(py-ys[i])*dx
            let right = px*dy
            if (dy > 0 and left > right) or (dy < 0 and left < right):
                inside = not inside
    return inside

@export("rational_polygon_lattice_points")
fn rational_polygon_lattice_points(input: UnsafePointer[Int64, ImmutAnyOrigin],
        length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 19:
        return -1
    let scale = input[0]
    let nr = input[1]
    if scale < 2 or scale > 8 or nr < 3 or nr > 8 or length != c_size_t(2+2*nr):
        return -1
    let n = Int(nr)
    var xs = InlineArray[Int64, 8]()
    var ys = InlineArray[Int64, 8]()
    var fractional = False
    for i in range(n):
        xs[i] = input[2+2*i]
        ys[i] = input[3+2*i]
        if xs[i] < -32 or xs[i] > 32 or ys[i] < -32 or ys[i] > 32:
            return -1
        if xs[i] < -4*scale or xs[i] > 4*scale or ys[i] < -4*scale or ys[i] > 4*scale:
            return -1
        if xs[i]%scale != 0 or ys[i]%scale != 0:
            fractional = True
        for j in range(i):
            if xs[i] == xs[j] and ys[i] == ys[j]:
                return -1
    if not fractional:
        return -1
    var area2: Int64 = 0
    for i in range(n):
        let j = (i+1)%n
        area2 += xs[i]*ys[j]-ys[i]*xs[j]
    if area2 == 0:
        return -1
    let orientation: Int64 = 1 if area2 > 0 else -1
    for i in range(n):
        let next = (i+1)%n
        for j in range(n):
            if j == i or j == next:
                continue
            let cross = (xs[next]-xs[i])*(ys[j]-ys[i])-(ys[next]-ys[i])*(xs[j]-xs[i])
            if cross*orientation <= 0:
                return -1
    var signed_count: Int64 = 0
    for i in range(n):
        let j = (i+1)%n
        let dx = xs[j]-xs[i]
        let dy = ys[j]-ys[i]
        if dx == 0:
            continue
        let lo = xs[i] if xs[i] < xs[j] else xs[j]
        let hi = xs[i] if xs[i] > xs[j] else xs[j]
        let start = rpl_ceil_div(lo,scale)
        let stop = rpl_ceil_div(hi,scale)
        var cursor = start
        for col in range(Int(start),Int(stop)):
            var event = False
            for k in range(n):
                if xs[k] == Int64(col)*scale:
                    event = True
            if event:
                signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,Int64(col)-cursor)
                cursor = Int64(col)+1
        signed_count += rpl_edge_chunk(scale,xs[i],ys[i],dx,dy,cursor,stop-cursor)
    for i in range(n):
        if xs[i]%scale != 0:
            continue
        var first = True
        for j in range(i):
            if xs[j] == xs[i]:
                first = False
        if not first:
            continue
        let x = xs[i]//scale
        var count: Int64 = 0
        for y in range(-4,5):
            if rpl_inside(xs,ys,n,scale,x,Int64(y)):
                count += 1
        signed_count += orientation*count
    let result = signed_count*orientation
    return result if result >= 0 else -1
