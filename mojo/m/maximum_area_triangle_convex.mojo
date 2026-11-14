# Independent draft; compilation and output remain unverified.
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn triangle_cross(p: UnsafePointer[Int64, ImmutAnyOrigin], a: Int, b: Int, c: Int) -> Int64:
    let ax=p[1+2*a]
    let ay=p[2+2*a]
    return (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax)

@export("maximum_area_triangle_convex")
fn maximum_area_triangle_convex(p: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if p==UnsafePointer[Int64, ImmutAnyOrigin]() or length==0: return -1
    if p[0]<3 or p[0]>1024: return -1
    let n=Int(p[0])
    if length!=c_size_t(1+2*n): return -1
    for i in range(1,Int(length)):
        if p[i]< -1000000 or p[i]>1000000: return -1
    for i in range(n):
        let next=(i+1)%n
        for j in range(n):
            if j!=i and j!=next and triangle_cross(p,i,next,j)<=0: return -1
    var best: Int64=0
    for i in range(n-2):
        for j in range(i+1,n-1):
            var lo=j+1
            var hi=n-1
            while lo<hi:
                let mid=lo+(hi-lo)//2
                if triangle_cross(p,i,j,mid)<triangle_cross(p,i,j,mid+1): lo=mid+1
                else: hi=mid
            let value=triangle_cross(p,i,j,lo)
            if value>best: best=value
    return best
