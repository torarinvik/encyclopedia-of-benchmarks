module ramer_douglas_peucker;

extern fn double sqrt(double value);
extern fn double hypot(double x, double y);
extern fn double fabs(double value);

const usz MAX_POINTS = 12;

fn double py_distance(double* p, usz a, usz b, usz k) {
    double ax=p[2*a], ay=p[2*a+1];
    double dx=p[2*b]-ax, dy=p[2*b+1]-ay;
    double px=p[2*k], py=p[2*k+1];
    double l2=dx*dx+dy*dy;
    double t=((px-ax)*dx+(py-ay)*dy)/l2;
    if (t < 0.0) t=0.0; else if (t > 1.0) t=1.0;
    double nx=ax+t*dx, ny=ay+t*dy;
    return hypot(px-nx, py-ny);
}

fn double rust_distance(double* p, usz a, usz b, usz k, double line_len) {
    double ax=p[2*a], ay=p[2*a+1], bx=p[2*b], by=p[2*b+1];
    double dx=bx-ax, dy=by-ay, px=p[2*k], py=p[2*k+1];
    double numerator=(((dy*px)-(dx*py))+(bx*ay))-(by*ax);
    return fabs(numerator)/line_len;
}

fn bool valid_geometry(double* p, usz n, double epsilon) {
    if (n < 3) return true;
    for (usz i=0;i<n;i++) for (usz j=0;j<i;j++) {
        if (p[2*i]==p[2*j] && p[2*i+1]==p[2*j+1]) return false;
    }
    for (usz i=0;i+2<n;i++) for (usz j=i+2;j<n;j++) {
        double ax=p[2*i], ay=p[2*i+1];
        double dx=p[2*j]-ax, dy=p[2*j+1]-ay;
        double l2=dx*dx+dy*dy;
        if (l2!=l2 || l2<=0.0) return false;
        double ll=sqrt(l2);
        if (ll!=ll || ll<=0.0) return false;
        double mp=0.0, mr=0.0; usz ip=i, ir=i;
        for (usz k=i+1;k<j;k++) {
            double px=p[2*k], py=p[2*k+1];
            double t=((px-ax)*dx+(py-ay)*dy)/l2;
            if (!(t>=0.0 && t<=1.0)) return false;
            double dp=py_distance(p,i,j,k), dr=rust_distance(p,i,j,k,ll);
            if (dp!=dp || dr!=dr) return false;
            if (dp>mp) { mp=dp; ip=k; }
            if (dr>mr) { mr=dr; ir=k; }
        }
        if (ip!=ir || ((mp>epsilon)!=(mr>epsilon))) return false;
    }
    return true;
}

fn void simplify(double* p, usz a, usz b, double epsilon, bool* keep) {
    if (b<=a+1) return;
    double best=0.0; usz index=a;
    for (usz k=a+1;k<b;k++) {
        double d=py_distance(p,a,b,k);
        if (d>best) { best=d; index=k; }
    }
    if (best>epsilon) {
        keep[index]=true;
        simplify(p,a,index,epsilon,keep);
        simplify(p,index,b,epsilon,keep);
    }
}

fn long ramer_douglas_peucker(double* input, usz input_length,
                              double* output, usz output_capacity) @export("ramer_douglas_peucker") {
    if (input==null || input_length<2 || input_length>26) return -1L;
    double count_value=input[0];
    if (count_value!=count_value || count_value<0.0 || count_value>12.0 || (double)(long)count_value!=count_value) return -1L;
    usz n=(usz)(long)count_value;
    double epsilon=input[1];
    if (input_length!=2+2*n || epsilon!=epsilon || epsilon<0.0 || epsilon>100.0) return -1L;
    double[24] points=zeroed;
    for (usz i=0;i<2*n;i++) {
        double x=input[2+i];
        if (x!=x || x < -100.0 || x > 100.0) return -1L;
        points[i]=x;
    }
    if (!valid_geometry(&points[0],n,epsilon)) return -1L;
    bool[12] keep=zeroed;
    if (n>0) keep[0]=true;
    if (n>1) keep[n-1]=true;
    if (n>2) simplify(&points[0],0,n-1,epsilon,&keep[0]);
    double[25] staged=zeroed; usz outn=0;
    for (usz i=0;i<n;i++) if (keep[i]) {
        staged[1+2*outn]=points[2*i];
        staged[2+2*outn]=points[2*i+1];
        outn++;
    }
    staged[0]=(double)outn; usz result_length=1+2*outn;
    if (output==null || output_capacity<result_length) return -2L;
    for (usz i=0;i<result_length;i++) output[i]=staged[i];
    return (long)result_length;
}
