module tsvc_s222_interleaved_square_recurrence;
extern fn double trunc(double value);
extern fn double fabs(double value);
fn bool seed_ok(double x) { return x == -1.0 || x == -0.5 || x == 0.0 || x == 0.5 || x == 1.0; }

fn long tsvc_s222_interleaved_square_recurrence(double* input, usz length, double* output, usz capacity)
    @export("tsvc_s222_interleaved_square_recurrence") {
    if (input == null || length < 5 || length > 257) return -1;
    double rn=input[0];
    if (rn != rn || trunc(rn) != rn || rn < 1.0 || rn > 64.0) return -1;
    usz n=(usz)rn;
    if (length != 1+4*n) return -1;
    for (usz i=1; i<1+3*n; i++)
        if (input[i] != input[i] || trunc(input[i]) != input[i] || fabs(input[i]) > 2.0) return -1;
    for (usz i=1+3*n; i<length; i++)
        if (input[i] != input[i] || !seed_ok(input[i])) return -1;
    usz required=2*n;
    if (output == null || capacity < required) return -2;
    double a[64]; double e[64];
    for (usz i=0; i<n; i++) { a[i]=input[1+i]; e[i]=input[1+3*n+i]; }
    for (usz i=1; i<n; i++) {
        double product=input[1+n+i]*input[1+2*n+i];
        a[i]=a[i]+product;
        e[i]=e[i-1]*e[i-1];
        a[i]=a[i]-product;
    }
    for (usz i=0; i<n; i++) { output[i]=a[i]; output[n+i]=e[i]; }
    return (long)required;
}
