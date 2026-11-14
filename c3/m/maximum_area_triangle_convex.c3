// Independent draft; compilation and output are unverified.
module maximum_area_triangle_convex;

fn long triangle_cross(long* p, usz a, usz b, usz c) {
    long ax=p[1+2*a], ay=p[2+2*a];
    return (p[1+2*b]-ax)*(p[2+2*c]-ay)-(p[2+2*b]-ay)*(p[1+2*c]-ax);
}

fn long maximum_area_triangle_convex(long* p, usz length) @export("maximum_area_triangle_convex") {
    if (p==null || length==0 || p[0]<3 || p[0]>1024) return -1;
    usz n=p[0].usz();
    if (length!=1+2*n) return -1;
    for (usz i=1; i<length; i++) if (p[i]< -1000000 || p[i]>1000000) return -1;
    for (usz i=0; i<n; i++) {
        usz next=(i+1)%n;
        for (usz j=0; j<n; j++)
            if (j!=i && j!=next && triangle_cross(p,i,next,j)<=0) return -1;
    }
    long best=0;
    for (usz i=0; i+2<n; i++) for (usz j=i+1; j+1<n; j++) {
        usz lo=j+1, hi=n-1;
        while (lo<hi) {
            usz mid=lo+(hi-lo)/2;
            if (triangle_cross(p,i,j,mid)<triangle_cross(p,i,j,mid+1)) lo=mid+1;
            else hi=mid;
        }
        long value=triangle_cross(p,i,j,lo);
        if (value>best) best=value;
    }
    return best;
}
