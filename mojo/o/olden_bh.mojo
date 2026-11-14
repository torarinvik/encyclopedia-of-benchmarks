from std.collections import List
from std.ffi import c_size_t
from std.math import sqrt
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

@export("olden_bh")
fn olden_bh(input: UnsafePointer[Float64, ImmutAnyOrigin], length: c_size_t,
        output: UnsafePointer[Float64, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Float64, ImmutAnyOrigin]() or length < 6: return -1
    let nv = input[0]; let theta = input[1]; let soft = input[2]
    if not (nv >= 2.0 and nv <= 16.0 and theta >= 0.0 and theta <= 2.0 and soft >= 0.0 and soft <= 1.0): return -1
    let n = Int(nv)
    if Float64(n) != nv or length != c_size_t(6+4*n): return -1
    var points = List[Float64](capacity=3*n)
    var masses = List[Float64](capacity=n)
    var minimum = List[Float64](length=3, fill=32.0)
    var maximum = List[Float64](length=3, fill=-32.0)
    var query = List[Float64](capacity=3)
    for axis in range(3):
        let v = input[3+axis]
        if not (v >= -32.0 and v <= 32.0): return -1
        query.append(v)
    for i in range(n):
        for axis in range(3):
            let v = input[6+4*i+axis]
            if not (v >= -32.0 and v <= 32.0): return -1
            if Float64(Int(v)) != v: return -1
            points.append(v)
            if v < minimum[axis]: minimum[axis] = v
            if v > maximum[axis]: maximum[axis] = v
        let mass = input[9+4*i]
        if not (mass >= 1.0 and mass <= 16.0): return -1
        masses.append(mass)
        for j in range(i):
            if points[3*i] == points[3*j] and points[3*i+1] == points[3*j+1] and points[3*i+2] == points[3*j+2]: return -1
    var inside = True
    for axis in range(3):
        if query[axis] < minimum[axis] or query[axis] > maximum[axis]: inside = False
    if inside: return -1
    var side = Float64(0.0)
    for axis in range(3):
        let span = maximum[axis]-minimum[axis]
        if span > side: side = span
    if side <= 0.0: return -1
    var masks = List[Int](capacity=1024)
    var children = List[Int](capacity=8192)
    var centers = List[Float64](capacity=3072)
    var sides = List[Float64](capacity=1024)
    var depths = List[Int](capacity=1024)
    var mass = List[Float64](capacity=1024)
    var weighted = List[Float64](capacity=3072)
    masks.append((1 << n)-1); sides.append(side); depths.append(0); mass.append(0.0)
    for axis in range(3): centers.append((minimum[axis]+maximum[axis])/2.0); weighted.append(0.0)
    for _ in range(8): children.append(-1)
    var node = 0
    while node < len(masks):
        let mask = masks[node]
        if (mask & (mask-1)) != 0:
            if depths[node] >= 16: return -1
            var parts = List[Int](length=8, fill=0)
            for body in range(n):
                if (mask & (1 << body)) == 0: continue
                var octant = 0
                for axis in range(3):
                    if points[3*body+axis] >= centers[3*node+axis]: octant |= 1 << axis
                parts[octant] |= 1 << body
            for octant in range(8):
                if parts[octant] == 0: continue
                if len(masks) >= 1024: return -1
                let child = len(masks)
                children[8*node+octant] = child
                masks.append(parts[octant]); sides.append(sides[node]/2.0); depths.append(depths[node]+1); mass.append(0.0)
                for axis in range(3):
                    var delta = -sides[node]/4.0
                    if (octant & (1 << axis)) != 0: delta = sides[node]/4.0
                    centers.append(centers[3*node+axis]+delta); weighted.append(0.0)
                for _ in range(8): children.append(-1)
        node += 1
    for reverse_node in range(len(masks)):
        let i = len(masks)-1-reverse_node
        let mask = masks[i]
        if (mask & (mask-1)) == 0:
            for body in range(n):
                if (mask & (1 << body)) != 0:
                    mass[i] = masses[body]
                    for axis in range(3): weighted[3*i+axis] = points[3*body+axis]
                    break
        else:
            for octant in range(8):
                let child = children[8*i+octant]
                if child < 0: continue
                mass[i] += mass[child]
                for axis in range(3): weighted[3*i+axis] += mass[child]*weighted[3*child+axis]
            for axis in range(3): weighted[3*i+axis] /= mass[i]
    if output == UnsafePointer[Float64, MutAnyOrigin]() or capacity < 4: return -2
    var stack = List[Int](capacity=1024)
    stack.append(0)
    var potential = Float64(0.0)
    var acceleration = List[Float64](length=3, fill=0.0)
    while len(stack) > 0:
        let i = stack.pop()
        let dx = weighted[3*i]-query[0]; let dy = weighted[3*i+1]-query[1]; let dz = weighted[3*i+2]-query[2]
        let distance = dx*dx+dy*dy+dz*dz
        let mask = masks[i]
        if (mask & (mask-1)) != 0 and theta*theta*distance < sides[i]*sides[i]:
            for reverse_octant in range(8):
                let child = children[8*i+7-reverse_octant]
                if child >= 0: stack.append(child)
        else:
            let r2 = distance+soft*soft
            let contribution = mass[i]/sqrt(r2)
            potential -= contribution
            let scale = contribution/r2
            acceleration[0] += dx*scale; acceleration[1] += dy*scale; acceleration[2] += dz*scale
    output[0] = potential
    for axis in range(3): output[1+axis] = acceleration[axis]
    return 4
