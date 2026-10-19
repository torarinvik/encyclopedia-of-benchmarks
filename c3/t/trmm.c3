// PolyBench/C trmm kernel, bounded port. Ohio State Software Distribution License: see benchmarks/t/trmm/LICENSE.txt.

module trmm;
extern fn double trunc(double value);
const long MAX_M = 8;
const long MAX_N = 8;

fn long trmm(double* input, usz length, double* output, usz capacity) @export("trmm") {
    if (input == null || length != 2) return -1;
    double m_value = input[0], n_value = input[1];
    if (m_value != m_value || n_value != n_value || trunc(m_value) != m_value || trunc(n_value) != n_value ||
        m_value < 1.0 || m_value > MAX_M || n_value < 1.0 || n_value > MAX_N) return -1;
    usz m = (usz)m_value, n = (usz)n_value, required = m*n;
    if (output == null || capacity < required) return -2;
    double a[MAX_M][MAX_M] = {0.0};
    double b[MAX_M][MAX_N] = {0.0};
    for (usz i = 0; i < m; i++) {
        for (usz j = 0; j < i; j++) a[i][j] = (double)((i+j)%m)/(double)m;
        a[i][i] = 1.0;
        for (usz j = 0; j < n; j++) b[i][j] = (double)((n+i-j)%n)/(double)n;
    }
    for (usz i = 0; i < m; i++) for (usz j = 0; j < n; j++) {
        for (usz k = i+1; k < m; k++) b[i][j] += a[k][i]*b[k][j];
        b[i][j] = 1.5*b[i][j];
    }
    double staged[MAX_M*MAX_N];
    for (usz i = 0; i < m; i++) for (usz j = 0; j < n; j++) staged[i*n+j] = b[i][j];
    for (usz i = 0; i < required; i++) output[i] = staged[i];
    return (long)required;
}
