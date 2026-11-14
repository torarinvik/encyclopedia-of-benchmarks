from std.collections import List
from std.ffi import c_size_t
from std.math import isfinite, sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("euclidean_t_spanner")
fn euclidean_t_spanner(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
                       output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 6 or length > 18: return -1
    let raw_n = input[0]
    let t = input[1]
    if not isfinite(raw_n) or raw_n < 2.0 or raw_n > 8.0: return -1
    let n = Int(raw_n)
    if Float64(n) != raw_n or length != c_size_t(2 + 2*n): return -1
    if not isfinite(t) or t < 1.5 or t > 4.0: return -1
    let separation = 4.0 * (t + 1.0) / (t - 1.0)
    var x = List[Float64](capacity=n)
    var y = List[Float64](capacity=n)
    for i in range(n):
        let px = input[2+2*i]
        let py = input[3+2*i]
        if not isfinite(px) or not isfinite(py) or px < -1000.0 or px > 1000.0 or py < -1000.0 or py > 1000.0: return -1
        if Float64(Int(px)) != px or Float64(Int(py)) != py: return -1
        for j in range(i):
            if x[j] == px and y[j] == py: return -1
        x.append(px); y.append(py)
    var masks = List[Int](capacity=15)
    var left = List[Int](capacity=15)
    var right = List[Int](capacity=15)
    var representative = List[Int](capacity=15)
    var cx = List[Float64](capacity=15)
    var cy = List[Float64](capacity=15)
    var radius = List[Float64](capacity=15)
    var span = List[Float64](capacity=15)
    for _ in range(15):
        masks.append(0); left.append(-1); right.append(-1); representative.append(0)
        cx.append(0.0); cy.append(0.0); radius.append(0.0); span.append(0.0)
    masks[0] = (1 << n) - 1
    var used = 1
    var node = 0
    while node < used:
        var members = List[Int](capacity=n)
        for i in range(n):
            if (masks[node] & (1 << i)) != 0: members.append(i)
        representative[node] = members[0]
        var min_x = x[members[0]]; var max_x = min_x
        var min_y = y[members[0]]; var max_y = min_y
        for point in members:
            if x[point] < min_x: min_x = x[point]
            if x[point] > max_x: max_x = x[point]
            if y[point] < min_y: min_y = y[point]
            if y[point] > max_y: max_y = y[point]
        cx[node] = (min_x + max_x) / 2.0
        cy[node] = (min_y + max_y) / 2.0
        let hx = (max_x - min_x) / 2.0; let hy = (max_y - min_y) / 2.0
        radius[node] = sqrt(hx*hx + hy*hy)
        span[node] = max_x - min_x
        if max_y - min_y > span[node]: span[node] = max_y - min_y
        if len(members) > 1:
            let axis_x = max_x - min_x >= max_y - min_y
            for i in range(1, len(members)):
                let point = members[i]
                var j = i
                while j > 0:
                    let prior = members[j-1]
                    var less = False
                    if axis_x:
                        less = x[point] < x[prior] or (x[point] == x[prior] and (y[point] < y[prior] or (y[point] == y[prior] and point < prior)))
                    else:
                        less = y[point] < y[prior] or (y[point] == y[prior] and (x[point] < x[prior] or (x[point] == x[prior] and point < prior)))
                    if not less: break
                    members[j] = prior
                    j -= 1
                members[j] = point
            left[node] = used; right[node] = used + 1
            used += 2
            let middle = len(members) // 2
            for i in range(len(members)):
                if i < middle: masks[left[node]] |= 1 << members[i]
                else: masks[right[node]] |= 1 << members[i]
        node += 1
    # A stack reproduces the depth-first node and pair traversal order.
    var kind = List[Int](capacity=64)
    var first = List[Int](capacity=64)
    var second = List[Int](capacity=64)
    var edges = List[Float64](capacity=56)
    kind.append(0); first.append(0); second.append(0)
    while len(kind) > 0:
        let event = kind.pop(); let a = first.pop(); let b = second.pop()
        if event == 0:
            if left[a] < 0: continue
            kind.append(1); first.append(left[a]); second.append(right[a])
            kind.append(0); first.append(right[a]); second.append(0)
            kind.append(0); first.append(left[a]); second.append(0)
        else:
            let dx = cx[a]-cx[b]; let dy = cy[a]-cy[b]
            var largest_radius = radius[a]
            if radius[b] > largest_radius: largest_radius = radius[b]
            if sqrt(dx*dx+dy*dy) - radius[a] - radius[b] >= separation * largest_radius:
                var u = representative[a]; var v = representative[b]
                if u > v:
                    let temp = u; u = v; v = temp
                edges.append(Float64(u)); edges.append(Float64(v))
            elif left[a] < 0:
                kind.append(1); first.append(right[b]); second.append(a)
                kind.append(1); first.append(left[b]); second.append(a)
            elif left[b] < 0 or span[a] > span[b]:
                kind.append(1); first.append(right[a]); second.append(b)
                kind.append(1); first.append(left[a]); second.append(b)
            else:
                kind.append(1); first.append(a); second.append(right[b])
                kind.append(1); first.append(a); second.append(left[b])
    let needed = 1 + len(edges)
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < c_size_t(needed): return -2
    output[0] = Float64(len(edges) // 2)
    for i in range(len(edges)): output[i+1] = edges[i]
    return Int64(needed)
