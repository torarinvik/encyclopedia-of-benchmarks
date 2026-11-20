module one_sided_jacobi_svd;

extern fn double sqrt(double value);
extern fn double fabs(double value);
const long MAX_N = 6;
const usz MAX_INPUT = 39;
const long MAX_SWEEPS = 128;
const double TOL = 1.0e-14;

fn long one_sided_jacobi_svd(long* input, usz length) @export("one_sided_jacobi_svd") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long m = input[0], n = input[1];
    if (n < 1 || n > MAX_N || m < n || m > MAX_N || length != (usz)(2 + m * n)) return -1;
    double a[36];
    for (long i = 0; i < 36; i++) a[i] = 0.0;
    for (long r = 0; r < m; r++) for (long c = 0; c < n; c++) {
        long x = input[2 + r * n + c];
        if (x < -8 || x > 8) return -1;
        a[r * n + c] = (double)x;
    }
    bool converged = false;
    for (long sweep = 0; sweep < MAX_SWEEPS; sweep++) {
        bool changed = false;
        for (long p = 0; p < n; p++) for (long q = p + 1; q < n; q++) {
            double alpha = 0.0, beta = 0.0, gamma = 0.0;
            for (long r = 0; r < m; r++) { double x = a[r*n+p], y = a[r*n+q]; alpha += x*x; beta += y*y; gamma += x*y; }
            if (alpha == 0.0 || beta == 0.0 || fabs(gamma) <= TOL * sqrt(alpha * beta)) continue;
            double tau = (beta - alpha) / (2.0 * gamma);
            double t = tau == 0.0 ? 1.0 : (tau > 0.0 ? 1.0 : -1.0) / (fabs(tau) + sqrt(1.0 + tau*tau));
            double c = 1.0 / sqrt(1.0 + t*t), s = c*t;
            for (long r = 0; r < m; r++) { double x = a[r*n+p], y = a[r*n+q]; a[r*n+p] = c*x-s*y; a[r*n+q] = s*x+c*y; }
            changed = true;
        }
        if (!changed) { converged = true; break; }
    }
    if (!converged) return -1;
    double sigma[6];
    for (long i = 0; i < 6; i++) sigma[i] = 0.0;
    for (long c = 0; c < n; c++) { for (long r = 0; r < m; r++) sigma[c] += a[r*n+c]*a[r*n+c]; sigma[c] = sqrt(sigma[c]); }
    for (long i = 0; i < n; i++) for (long j = i+1; j < n; j++) if (sigma[j] > sigma[i]) { double tmp=sigma[i]; sigma[i]=sigma[j]; sigma[j]=tmp; }
    double signature = 0.0;
    for (long i = 0; i < n; i++) signature += (double)(i+1) * sigma[i];
    return (long)(signature * 1000.0 + 0.5);
}
