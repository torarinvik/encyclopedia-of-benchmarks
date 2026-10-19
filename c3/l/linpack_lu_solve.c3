module linpack_lu_solve;
// ANSIbench LINPACK dgefa/dgesl profile; upstream source and stated modifications are public domain.
import "core:math";
const double INVALID_RESULT = -1.0e300;

fn int dgefa(double[16] *a, long n, long[4] *pivots) {
    int info = 0;
    long nm1 = n - 1;
    for (long k = 0; k < nm1; k++) {
        long l = k;
        double maximum = math.abs(a[n*k+k]);
        for (long i = 1; i < n-k; i++) {
            double candidate = math.abs(a[n*k+k+i]);
            if (candidate > maximum) { l = k+i; maximum = candidate; }
        }
        pivots[k] = l;
        if (a[n*k+l] != 0.0) {
            if (l != k) { double t=a[n*k+l]; a[n*k+l]=a[n*k+k]; a[n*k+k]=t; }
            double t = -1.0 / a[n*k+k];
            for (long i=0;i<n-k-1;i++) a[n*k+k+1+i]=t*a[n*k+k+1+i];
            for (long j=k+1;j<n;j++) {
                t=a[n*j+l];
                if (l!=k) { a[n*j+l]=a[n*j+k]; a[n*j+k]=t; }
                if (t != 0.0) for (long i=0;i<n-k-1;i++) a[n*j+k+1+i]=a[n*j+k+1+i]+t*a[n*k+k+1+i];
            }
        } else { info=(int)k; }
    }
    pivots[n-1]=n-1;
    if (a[n*(n-1)+n-1]==0.0) info=(int)(n-1);
    return info;
}

fn void dgesl(double[16] a, long n, long[4] pivots, double[4] *b) {
    for (long k=0;k<n-1;k++) {
        long l=pivots[k]; double t=b[l];
        if (l!=k) { b[l]=b[k]; b[k]=t; }
        if (t != 0.0) for (long i=0;i<n-k-1;i++) b[k+1+i]=b[k+1+i]+t*a[n*k+k+1+i];
    }
    for (long kb=0;kb<n;kb++) {
        long k=n-(kb+1); b[k]=b[k]/a[n*k+k]; double t=-b[k];
        if (t != 0.0) for (long i=0;i<k;i++) b[i]=b[i]+t*a[n*k+i];
    }
}

fn double linpack_lu_solve(long *input, usz length) @export("linpack_lu_solve") {
    if (input==null || length<1 || length>22) return INVALID_RESULT;
    long n=input[0]; if (n<2 || n>4 || length!=(usz)(1+n*n+n)) return INVALID_RESULT;
    double[16] a; double[4] b; long[4] pivots;
    for (long i=0;i<n*n;i++) { long v=input[1+i]; if(v < -8 || v > 8) return INVALID_RESULT; a[i]=(double)v; }
    for (long i=0;i<n;i++) { long v=input[1+n*n+i]; if(v < -32 || v > 32) return INVALID_RESULT; b[i]=(double)v; }
    if (dgefa(&a,n,&pivots)!=0) return INVALID_RESULT;
    dgesl(a,n,pivots,&b);
    double result=0.0; for(long i=0;i<n;i++) result=result+(double)(i+1)*b[i];
    return math.is_finite(result) ? result : INVALID_RESULT;
}
