// Independent draft; compilation and output are unverified.
fn cross(p: []const i64, a: usize, b: usize, c: usize) i64 {
    const ax=p[1+2*a]; const ay=p[2+2*a];
    return (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax);
}

export fn maximum_area_triangle_convex(input: ?[*]const i64, length: usize) i64 {
    if (input==null or length==0) return -1;
    const p=input.?[0..length];
    if (p[0]<3 or p[0]>1024) return -1;
    const n: usize=@intCast(p[0]);
    if (length!=1+2*n) return -1;
    for (p[1..]) |v| if (v< -1000000 or v>1000000) return -1;
    for (0..n) |i| {
        const next=(i+1)%n;
        for (0..n) |j| if (j!=i and j!=next and cross(p,i,next,j)<=0) return -1;
    }
    var best: i64=0;
    for (0..n-2) |i| for (i+1..n-1) |j| {
        var lo=j+1; var hi=n-1;
        while (lo<hi) {
            const mid=lo+(hi-lo)/2;
            if (cross(p,i,j,mid)<cross(p,i,j,mid+1)) lo=mid+1 else hi=mid;
        }
        best=@max(best,cross(p,i,j,lo));
    };
    return best;
}
