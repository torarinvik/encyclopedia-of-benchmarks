# Static two-dimensional range tree with sorted per-node y catalogs.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("orthogonal_range_reporting_2d")
fn orthogonal_range_reporting_2d(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 2 or length > 50: return -1
    let nv = input[0]
    let qv = input[1]
    if nv < 1 or nv > 8 or qv < 1 or qv > 8 or length != c_size_t(2+2*nv+4*qv): return -1
    let n = Int(nv)
    let q = Int(qv)
    var xs = List[Int64](capacity=n)
    var ys = List[Int64](capacity=n)
    var order = List[Int](capacity=n)
    var queries = List[Int64](capacity=4*q)
    for i in range(n):
        let x = input[2+2*i]
        let y = input[3+2*i]
        if x < 0 or x > 15 or y < 0 or y > 15: return -1
        for j in range(i):
            if xs[j] == x and ys[j] == y: return -1
        xs.append(x); ys.append(y); order.append(i)
    for i in range(q):
        let offset = 2+2*n+4*i
        let xl = input[offset]
        let xh = input[offset+1]
        let yl = input[offset+2]
        let yh = input[offset+3]
        if xl < 0 or xl > xh or xh > 15 or yl < 0 or yl > yh or yh > 15: return -1
        queries.append(xl); queries.append(xh); queries.append(yl); queries.append(yh)
    for i in range(1,n):
        let item = order[i]
        var j = i
        while j > 0:
            let prior = order[j-1]
            if xs[prior] < xs[item] or (xs[prior] == xs[item] and ys[prior] <= ys[item]): break
            order[j] = prior
            j -= 1
        order[j] = item
    var catalog = List[Int](capacity=128)
    var sizes = List[Int](capacity=16)
    for _ in range(128): catalog.append(0)
    for _ in range(16): sizes.append(0)
    for i in range(n):
        catalog[(8+i)*8] = order[i]
        sizes[8+i] = 1
    var node = 8
    while node > 1:
        node -= 1
        let l = 2*node
        let r = l+1
        var a = 0
        var b = 0
        while a < sizes[l] or b < sizes[r]:
            var take_left = b >= sizes[r]
            if a < sizes[l] and b < sizes[r]:
                let left_id = catalog[8*l+a]
                let right_id = catalog[8*r+b]
                take_left = ys[left_id] < ys[right_id] or (ys[left_id] == ys[right_id] and left_id < right_id)
            if take_left:
                catalog[8*node+sizes[node]] = catalog[8*l+a]
                a += 1
            else:
                catalog[8*node+sizes[node]] = catalog[8*r+b]
                b += 1
            sizes[node] += 1
    var fields = List[Int64](capacity=73)
    fields.append(qv)
    for query in range(q):
        let xl = queries[4*query]
        let xh = queries[4*query+1]
        let yl = queries[4*query+2]
        let yh = queries[4*query+3]
        var low = 0
        var high = n
        while low < high:
            let mid = (low+high) // 2
            if xs[order[mid]] < xl: low = mid+1
            else: high = mid
        var first = low+8
        low = 0; high = n
        while low < high:
            let mid = (low+high) // 2
            if xs[order[mid]] <= xh: low = mid+1
            else: high = mid
        var last = low+8
        var hit_mask = 0
        while first < last:
            var selected = -1
            if (first & 1) != 0:
                selected = first
                first += 1
            elif (last & 1) != 0:
                last -= 1
                selected = last
            else:
                first //= 2
                last //= 2
                continue
            low = 0; high = sizes[selected]
            while low < high:
                let mid = (low+high) // 2
                if ys[catalog[8*selected+mid]] < yl: low = mid+1
                else: high = mid
            let begin = low
            high = sizes[selected]
            while low < high:
                let mid = (low+high) // 2
                if ys[catalog[8*selected+mid]] <= yh: low = mid+1
                else: high = mid
            for p in range(begin,low): hit_mask |= 1 << catalog[8*selected+p]
        var hits = 0
        for id in range(n):
            if (hit_mask & (1 << id)) != 0: hits += 1
        fields.append(Int64(hits))
        for id in range(n):
            if (hit_mask & (1 << id)) != 0: fields.append(Int64(id))
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for byte in range(8): output[8*i+byte] = UInt8((fields[i] >> (8*byte)) & 255)
    return Int64(bytes)
