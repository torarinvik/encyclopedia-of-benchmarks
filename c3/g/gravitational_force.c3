module gravitational_force;
extern fn double sqrt(double value);

fn long gravitational_force(double* v, usz n, double* out, usz cap) @export("gravitational_force") {
    if (v==null || n!=6) return -1;
    for (usz i=0; i<6; i++) if (v[i]!=v[i] || v[i]>1.0e100 || v[i]<-1.0e100) return -1;
    double m1=v[0], x1=v[1], y1=v[2], m2=v[3], x2=v[4], y2=v[5];
    if (m1>1.0e12 || m1< -1.0e12 || m2>1.0e12 || m2< -1.0e12 ||
        (m1!=0.0 && m1<1.0e-12 && m1> -1.0e-12) || (m2!=0.0 && m2<1.0e-12 && m2> -1.0e-12) ||
        x1>1.0e6 || x1< -1.0e6 || y1>1.0e6 || y1< -1.0e6 || x2>1.0e6 || x2< -1.0e6 || y2>1.0e6 || y2< -1.0e6) return -1;
    double dx=x1-x2, dy=y1-y2, d2=dx*dx+dy*dy;
    if (d2!=0.0 && d2<1.0e-12) return -1;
    if (out==null || cap<2) return -2;
    if (d2==0.0) { out[0]=0.0; out[1]=0.0; return 2; }
    double distance=sqrt(d2), magnitude=6.67430e-11*m1*m2/d2;
    out[0]=magnitude*(dx/distance); out[1]=magnitude*(dy/distance);
    return 2;
}
