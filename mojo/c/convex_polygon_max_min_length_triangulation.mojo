from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn ml_orient(points: InlineArray[Int64, 12], a: Int, b: Int, c: Int) -> Int64:
    let ax=points[2*a]; let ay=points[2*a+1]
    let bx=points[2*b]; let by=points[2*b+1]
    let cx=points[2*c]; let cy=points[2*c+1]
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)

fn ml_distance_squared(points: InlineArray[Int64, 12], a: Int, b: Int) -> Int64:
    let dx=points[2*a]-points[2*b]
    let dy=points[2*a+1]-points[2*b+1]
    return dx*dx+dy*dy

fn ml_diagonal_bit(n: Int, a0: Int, b0: Int) -> Int:
    let left=min(a0,b0)
    let right=max(a0,b0)
    var bit=0
    for first in range(n):
        for second in range(first+2,n):
            if first==0 and second==n-1: continue
            if first==left and second==right: return bit
            bit+=1
    return -1

fn ml_angle_at_least_sixty(points: InlineArray[Int64, 12], p: Int, q: Int, r: Int) -> Bool:
    let ux=points[2*p]-points[2*q]
    let uy=points[2*p+1]-points[2*q+1]
    let vx=points[2*r]-points[2*q]
    let vy=points[2*r+1]-points[2*q+1]
    let dot=ux*vx+uy*vy
    if dot<=0: return True
    let norm_u=ux*ux+uy*uy
    let norm_v=vx*vx+vy*vy
    return 4*dot*dot<=norm_u*norm_v

fn ml_greedy(points: InlineArray[Int64, 12], n: Int) -> Int64:
    var next=InlineArray[Int,6](fill=0)
    for i in range(n): next[i]=(i+1)%n
    var shortest=Int64(513)
    for i in range(n):
        let edge=ml_distance_squared(points,i,(i+1)%n)
        if edge<shortest: shortest=edge
    var active=n
    var p=0
    var q=next[p]
    var r=next[q]
    var steps=0
    var diagonal_mask=Int64(0)
    while active>3:
        steps+=1
        if steps>4*n: return -1
        if ml_angle_at_least_sixty(points,p,q,r):
            let chord=ml_distance_squared(points,p,r)
            if chord<shortest: shortest=chord
            let bit=ml_diagonal_bit(n,p,r)
            if bit<0: return -1
            diagonal_mask |= Int64(1) << bit
            next[p]=r
            active-=1
            q=r
            r=next[r]
        else:
            p=q
            q=r
            r=next[r]
    return shortest*512+diagonal_mask

@export("convex_polygon_max_min_length_triangulation")
fn convex_polygon_max_min_length_triangulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64, ImmutAnyOrigin]() or length<1 or length>14: return -1
    if input[0]<3 or input[0]>6: return -1
    let n=Int(input[0])
    if length!=c_size_t(1+2*n): return -1
    var points=InlineArray[Int64,12](fill=0)
    for i in range(n):
        let x=input[1+2*i]
        let y=input[2+2*i]
        if x < -8 or x > 8 or y < -8 or y > 8: return -1
        for j in range(i):
            if points[2*j]==x and points[2*j+1]==y: return -1
        points[2*i]=x
        points[2*i+1]=y
    var area2:Int64=0
    for i in range(n):
        let following=(i+1)%n
        area2+=points[2*i]*points[2*following+1]-points[2*i+1]*points[2*following]
    if area2<=0: return -1
    for a in range(n):
        for b in range(a+1,n):
            for c in range(b+1,n):
                if ml_orient(points,a,b,c)==0: return -1
    for edge in range(n):
        let following=(edge+1)%n
        for vertex in range(n):
            if vertex!=edge and vertex!=following and ml_orient(points,edge,following,vertex)<=0: return -1
    return ml_greedy(points,n)
