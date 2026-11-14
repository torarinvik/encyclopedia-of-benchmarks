from std.collections import List
from std.ffi import c_size_t
from std.math import floor, sqrt
from std.memory import ImmutAnyOrigin, UnsafePointer

fn olden_tsp_distance(x: List[Int64], y: List[Int64], a: Int, b: Int) -> Float64:
    let dx = Float64(x[a]-x[b]); let dy = Float64(y[a]-y[b])
    return sqrt(dx*dx+dy*dy)

fn olden_tsp_edge(start: Int, point: Int, x: List[Int64], y: List[Int64], next: List[Int], prev: List[Int]) -> (Int, Int, Float64, Float64):
    var nearest = start
    var distance = olden_tsp_distance(x,y,point,start)
    var current = next[start]
    while current != start:
        let candidate = olden_tsp_distance(x,y,point,current)
        if candidate < distance: nearest = current; distance = candidate
        current = next[current]
    let after = next[nearest]; let before = prev[nearest]
    let to_after = olden_tsp_distance(x,y,point,after)
    let to_before = olden_tsp_distance(x,y,point,before)
    let old_after = olden_tsp_distance(x,y,nearest,after)
    let old_before = olden_tsp_distance(x,y,nearest,before)
    if to_before-old_before < to_after-old_after:
        return (before,nearest,distance,to_before)
    return (nearest,after,to_after,distance)

fn olden_tsp_conquer(order: List[Int], x: List[Int64], y: List[Int64], mut next: List[Int], mut prev: List[Int]) -> Int:
    let cycle = order[0]
    next[cycle] = cycle; prev[cycle] = cycle
    for i in range(1,len(order)):
        let point = order[i]
        let (before,after,_,_) = olden_tsp_edge(cycle,point,x,y,next,prev)
        next[before] = point; prev[point] = before
        next[point] = after; prev[after] = point
    return cycle

fn olden_tsp_reverse(start: Int, mut next: List[Int], mut prev: List[Int]):
    var current = start
    for _ in range(3):
        let following = next[current]
        next[current] = prev[current]
        prev[current] = following
        current = following

@export("olden_tsp")
fn olden_tsp(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or (length != 7 and length != 15): return -1
    let nv = input[0]
    if (nv != 3 and nv != 7) or length != c_size_t(1+2*Int(nv)): return -1
    let n = Int(nv)
    var x = List[Int64](capacity=n); var y = List[Int64](capacity=n)
    for i in range(n):
        let px = input[1+2*i]; let py = input[2+2*i]
        if px < -8 or px > 8 or py < -8 or py > 8: return -1
        x.append(px); y.append(py)
    var next = List[Int](length=n, fill=0)
    var prev = List[Int](length=n, fill=0)
    if n == 3:
        var order = List[Int](capacity=3)
        order.append(1); order.append(2); order.append(0)
        _ = olden_tsp_conquer(order,x,y,next,prev)
    else:
        var left_order = List[Int](capacity=3)
        var right_order = List[Int](capacity=3)
        left_order.append(3); left_order.append(4); left_order.append(1)
        right_order.append(5); right_order.append(6); right_order.append(2)
        let a = olden_tsp_conquer(left_order,x,y,next,prev)
        let b = olden_tsp_conquer(right_order,x,y,next,prev)
        let (p1,n1,tton1,ttop1) = olden_tsp_edge(a,0,x,y,next,prev)
        let (p2,n2,tton2,ttop2) = olden_tsp_edge(b,0,x,y,next,prev)
        var best = ttop1+ttop2+olden_tsp_distance(x,y,n1,n2)
        var choice = 1
        var test = ttop1+tton2+olden_tsp_distance(x,y,n1,p2)
        if test < best: best = test; choice = 2
        test = tton1+ttop2+olden_tsp_distance(x,y,p1,n2)
        if test < best: best = test; choice = 3
        test = tton1+tton2+olden_tsp_distance(x,y,p1,p2)
        if test < best: choice = 4
        if choice == 1:
            olden_tsp_reverse(n2,next,prev)
            next[p1] = 0; prev[0] = p1; next[0] = p2; prev[p2] = 0
            next[n2] = n1; prev[n1] = n2
        elif choice == 2:
            next[p1] = 0; prev[0] = p1; next[0] = n2; prev[n2] = 0
            next[p2] = n1; prev[n1] = p2
        elif choice == 3:
            next[p2] = 0; prev[0] = p2; next[0] = n1; prev[n1] = 0
            next[p1] = n2; prev[n2] = p1
        else:
            olden_tsp_reverse(n1,next,prev)
            next[n1] = 0; prev[0] = n1; next[0] = n2; prev[n2] = 0
            next[p2] = p1; prev[p1] = p2
    var total = Float64(0.0)
    var city = 0
    for _ in range(n):
        let following = next[city]
        total += olden_tsp_distance(x,y,city,following)
        city = following
    return Int64(floor(total*1000.0+0.5))
