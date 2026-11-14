// Independent draft; compilation and output remain unverified.
fn triangle_cross(p &i64, a int, b int, c int) i64 {
    unsafe {
        ax,ay:=p[1+2*a],p[2+2*a]
        return (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax)
    }
}

@[export: 'maximum_area_triangle_convex']
pub fn maximum_area_triangle_convex(p &i64, length usize) i64 {
    if length==0 { return -1 }
    unsafe {
        if p==nil || p[0]<3 || p[0]>1024 { return -1 }
        n:=int(p[0])
        if length!=usize(1+2*n) { return -1 }
        for i in 1 .. int(length) { if p[i]< -1000000 || p[i]>1000000 { return -1 } }
        for i in 0 .. n {
            next:=(i+1)%n
            for j in 0 .. n {
                if j!=i && j!=next && triangle_cross(p,i,next,j)<=0 { return -1 }
            }
        }
        mut best:=i64(0)
        for i in 0 .. n-2 { for j in i+1 .. n-1 {
            mut lo:=j+1
            mut hi:=n-1
            for lo<hi {
                mid:=lo+(hi-lo)/2
                if triangle_cross(p,i,j,mid)<triangle_cross(p,i,j,mid+1) { lo=mid+1 } else { hi=mid }
            }
            value:=triangle_cross(p,i,j,lo)
            if value>best { best=value }
        } }
        return best
    }
}
