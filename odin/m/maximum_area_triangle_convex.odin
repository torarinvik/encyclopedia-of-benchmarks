// Independent draft; compilation and output remain unverified.
package maximum_area_triangle_convex
import "core:c"

triangle_cross :: proc(p: [^]i64, a,b,c: int) -> i64 {
    ax,ay:=p[1+2*a],p[2+2*a]
    return (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax)
}

@(export)
maximum_area_triangle_convex :: proc "c" (p: [^]i64, length: c.size_t) -> i64 {
    if p==nil || length==0 do return -1
    if p[0]<3 || p[0]>1024 do return -1
    n:=int(p[0])
    if length!=c.size_t(1+2*n) do return -1
    for i:=1; i<int(length); i+=1 { if p[i]< -1000000 || p[i]>1000000 do return -1 }
    for i:=0; i<n; i+=1 {
        next:=(i+1)%n
        for j:=0; j<n; j+=1 {
            if j!=i && j!=next && triangle_cross(p,i,next,j)<=0 do return -1
        }
    }
    best:=i64(0)
    for i:=0; i+2<n; i+=1 { for j:=i+1; j+1<n; j+=1 {
        lo,hi:=j+1,n-1
        for lo<hi {
            mid:=lo+(hi-lo)/2
            if triangle_cross(p,i,j,mid)<triangle_cross(p,i,j,mid+1) { lo=mid+1 } else { hi=mid }
        }
        value:=triangle_cross(p,i,j,lo)
        if value>best { best=value }
    } }
    return best
}
