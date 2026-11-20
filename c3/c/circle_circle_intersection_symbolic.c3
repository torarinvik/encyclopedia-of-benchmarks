// Independently authored draft; not compiled or run.
module circle_circle_intersection_symbolic;
fn long circle_circle_intersection_symbolic(long* v, usz n, char* out, usz cap)
        @export("circle_circle_intersection_symbolic") {
    if (v == null || n != 6) return -1;
    for (usz i=0;i<6;i++) if (v[i] < -1000 || v[i] > 1000) return -1;
    if (v[2]<1 || v[5]<1) return -1;
    long dx=v[3]-v[0], dy=v[4]-v[1], d=dx*dx+dy*dy;
    long[7] words = {}; usz count=1;
    if (d==0) words[0]=v[2]==v[5] ? 3 : 0;
    else {
        long t=d+v[2]*v[2]-v[5]*v[5], h=4*v[2]*v[2]*d-t*t;
        if (h>=0) {
            long den=2*d; count=7;
            words[0]=h==0 ? 1 : 2; words[1]=den*v[0]+dx*t; words[2]=den*v[1]+dy*t;
            words[3]=den; words[4]=-dy; words[5]=dx; words[6]=h;
        }
    }
    usz needed=8*count;
    if (out==null || cap<needed) return -2;
    for (usz i=0;i<count;i++) {
        ulong bits=(ulong)words[i];
        for (usz j=0;j<8;j++) { out[8*i+j]=(char)(bits & 255); bits >>= 8; }
    }
    return (long)needed;
}
