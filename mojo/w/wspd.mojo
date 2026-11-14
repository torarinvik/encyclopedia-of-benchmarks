from std.collections import List
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("wspd")
fn wspd(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 18: return -1
    let nv = input[0]; let separation = input[1]
    if nv < 1 or nv > 8 or separation < 1 or separation > 8: return -1
    let n = Int(nv)
    if length != c_size_t(2+2*n): return -1
    var x = List[Int64](capacity=n)
    var y = List[Int64](capacity=n)
    for i in range(n):
        let px = input[2+2*i]; let py = input[3+2*i]
        if px < -1000 or px > 1000 or py < -1000 or py > 1000: return -1
        for j in range(i):
            if x[j] == px and y[j] == py: return -1
        x.append(px); y.append(py)
    var masks = List[Int](capacity=15)
    var left = List[Int](capacity=15)
    var right = List[Int](capacity=15)
    var cx = List[Float64](capacity=15)
    var cy = List[Float64](capacity=15)
    var radius = List[Float64](capacity=15)
    for _ in range(15):
        masks.append(0); left.append(-1); right.append(-1)
        cx.append(0.0); cy.append(0.0); radius.append(0.0)
    masks[0] = (1 << n)-1
    var used = 1
    var node = 0
    while node < used:
        var members = List[Int](capacity=n)
        for i in range(n):
            if (masks[node] & (1 << i)) != 0: members.append(i)
        var min_x = x[members[0]]; var max_x = min_x
        var min_y = y[members[0]]; var max_y = min_y
        for point in members:
            if x[point] < min_x: min_x = x[point]
            if x[point] > max_x: max_x = x[point]
            if y[point] < min_y: min_y = y[point]
            if y[point] > max_y: max_y = y[point]
        cx[node] = (Float64(min_x)+Float64(max_x))/2.0
        cy[node] = (Float64(min_y)+Float64(max_y))/2.0
        let hx = Float64(max_x-min_x)/2.0; let hy = Float64(max_y-min_y)/2.0
        radius[node] = sqrt(hx*hx+hy*hy)
        if len(members) > 1:
            let axis_x = max_x-min_x >= max_y-min_y
            for i in range(1,len(members)):
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
            left[node] = used; right[node] = used+1
            used += 2
            let middle = len(members)//2
            for i in range(len(members)):
                if i < middle: masks[left[node]] |= 1 << members[i]
                else: masks[right[node]] |= 1 << members[i]
        node += 1
    # Event kind 0 visits a node; kind 1 decomposes a pair.
    var kind = List[Int](capacity=64)
    var first = List[Int](capacity=64)
    var second = List[Int](capacity=64)
    kind.append(0); first.append(0); second.append(0)
    var fields = List[Int64](capacity=57)
    fields.append(0)
    while len(kind) > 0:
        let event = kind.pop(); let a = first.pop(); let b = second.pop()
        if event == 0:
            if left[a] < 0: continue
            kind.append(1); first.append(left[a]); second.append(right[a])
            kind.append(0); first.append(right[a]); second.append(0)
            kind.append(0); first.append(left[a]); second.append(0)
        else:
            var r = radius[a]
            if radius[b] > r: r = radius[b]
            let dx = cx[a]-cx[b]; let dy = cy[a]-cy[b]
            if sqrt(dx*dx+dy*dy)-2.0*r > Float64(separation)*r:
                if len(fields) >= 57: return -2
                fields.append(Int64(masks[a])); fields.append(Int64(masks[b]))
            elif radius[a] > radius[b]:
                kind.append(1); first.append(right[a]); second.append(b)
                kind.append(1); first.append(left[a]); second.append(b)
            else:
                kind.append(1); first.append(a); second.append(right[b])
                kind.append(1); first.append(a); second.append(left[b])
    fields[0] = Int64((len(fields)-1)//2)
    let bytes = 8*len(fields)
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(len(fields)):
        for j in range(8): output[8*i+j] = UInt8((fields[i] >> (8*j)) & 255)
    return Int64(bytes)
