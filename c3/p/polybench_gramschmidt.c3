// Clean-room bounded PolyBench QR port. See package LICENSE.txt.
module polybench_gramschmidt;
extern fn double sqrt(double value);
extern fn double trunc(double value);
const long MAX_SIDE = 6;

fn long polybench_gramschmidt(double* input, usz length, double* output, usz capacity) @export("polybench_gramschmidt") {
    if (input == null || length != 2) return -1;
    double mv = input[0], nv = input[1];
    if (mv != mv || nv != nv || trunc(mv) != mv || trunc(nv) != nv || mv < 1 || mv > MAX_SIDE || nv < 1 || nv > MAX_SIDE || nv > mv) return -1;
    usz m = (usz)mv, n = (usz)nv, q_cells = m*n, r_cells = n*n, total = q_cells+r_cells;
    if (output == null || capacity < total) return -2;
    double a[36] = {0.0}, q[36] = {0.0}, r[36] = {0.0}, staged[72] = {0.0};
    for (usz i=0;i<m;i++) for (usz j=0;j<n;j++) a[i*n+j]=((double)((i*j)%m)/(double)m)*100.0+10.0;
    for (usz k=0;k<n;k++) {
        double norm_squared=0.0;
        for (usz i=0;i<m;i++) norm_squared += a[i*n+k]*a[i*n+k];
        r[k*n+k]=sqrt(norm_squared);
        for (usz i=0;i<m;i++) q[i*n+k]=a[i*n+k]/r[k*n+k];
        for (usz j=k+1;j<n;j++) {
            r[k*n+j]=0.0;
            for (usz i=0;i<m;i++) r[k*n+j]+=q[i*n+k]*a[i*n+j];
            for (usz i=0;i<m;i++) a[i*n+j]=a[i*n+j]-q[i*n+k]*r[k*n+j];
        }
    }
    for (usz x=0;x<r_cells;x++) staged[x]=r[x];
    for (usz x=0;x<q_cells;x++) staged[r_cells+x]=q[x];
    for (usz x=0;x<total;x++) output[x]=staged[x];
    return (long)total;
}
