module durand_kerner_roots;
extern fn double sqrt(double value);
extern fn double hypot(double x, double y);
struct Complex { double r; double i; }
fn Complex sub(Complex a, Complex b) { return {a.r-b.r, a.i-b.i}; }
fn Complex mul(Complex a, Complex b) { return {a.r*b.r-a.i*b.i, a.r*b.i+a.i*b.r}; }
fn Complex divc(Complex a, Complex b) { double d=b.r*b.r+b.i*b.i; return {(a.r*b.r+a.i*b.i)/d,(a.i*b.r-a.r*b.i)/d}; }
fn double durand_kerner_roots_impl(long* v, usz n) {
    if (v == null || n != 3) return -1.0e300;
    long d=v[0]; long ri=v[1]; long part=v[2];
    if (d == 0 || d < -4 || d > 4 || ri < 0 || ri > 2 || part < 0 || part > 1) return -1.0e300;
    double s=d>0 ? 1.0 : -1.0; double q=sqrt(3.0)/2.0;
    Complex[3] z={{s,0.0},{-0.5*s,q*s},{-0.5*s,-q*s}};
    for (int it=0; it<100; it++) {
        Complex[3] next; double change=0.0;
        for (int i=0; i<3; i++) {
            Complex den={1.0,0.0};
            for (int j=0; j<3; j++) if (i!=j) den=mul(den,sub(z[i],z[j]));
            Complex z3=mul(mul(z[i],z[i]),z[i]);
            next[i]=sub(z[i],divc(sub(z3,{(double)d,0.0}),den));
            double delta=hypot(next[i].r-z[i].r,next[i].i-z[i].i);
            if (delta>change) change=delta;
        }
        for (int i=0; i<3; i++) z[i]=next[i];
        if (change<1.0e-14) break;
    }
    return part==0 ? z[ri].r : z[ri].i;
}
fn double durand_kerner_roots(long* v, usz n) @export("durand_kerner_roots") {
    return durand_kerner_roots_impl(v,n);
}
