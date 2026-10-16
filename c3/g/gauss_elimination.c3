module gauss_elimination;

extern fn double nearbyint(double value);
fn float abs_f(float x) { return x < 0.0 ? -x : x; }

fn void put_f64_le(double value, char* output, usz offset) {
    char* bytes = (char*)&value;
    for (usz b = 0; b < 8; b++) output[offset + b] = bytes[b];
}

fn long gauss_elimination(long* input, usz length, char* output, usz capacity) @export("gauss_elimination") {
    if (input == null || length < 1 || input[0] < 2 || input[0] > 8) return -1;
    usz n = (usz)input[0];
    if (length != 1 + n*n + n) return -1;
    for (usz i = 1; i < length; i++) if (input[i] < -100 || input[i] > 100) return -1;
    float[72] m;
    for (usz q = 0; q < 72; q++) m[q] = 0.0;
    for (usz r=0; r<n; r++) { for (usz c=0; c<n; c++) m[r*9+c]=(float)input[1+r*n+c]; m[r*9+n]=(float)input[1+n*n+r]; }
    for (usz i=0; i+1<n; i++) {
        usz pivot=i;
        for (usz j=i; j<n; j++) if (abs_f(m[j*9+i]) > abs_f(m[pivot*9+i])) pivot=j;
        if (m[pivot*9+i] == 0.0) return -1;
        if (pivot != i) for (usz l=0; l<=n; l++) { float t=m[i*9+l]; m[i*9+l]=m[pivot*9+l]; m[pivot*9+l]=t; }
        for (usz j=i+1; j<n; j++) {
            float tmp = -(m[j*9+i] / m[i*9+i]);
            for (usz l=0; l<=n; l++) m[j*9+l] = m[j*9+l] + m[i*9+l]*tmp;
        }
    }
    if (m[(n-1)*9+n-1] == 0.0) return -1;
    if (output == null || capacity < n*8) return -2;
    float[8] ans;
    for (usz q = 0; q < 8; q++) ans[q] = 0.0;
    usz k=n;
    while (k>0) { k--; float mul=0.0; usz l=n; while (l>k+1) { l--; mul=mul+m[k*9+l]*ans[l]; } ans[k]=(m[k*9+n]-mul)/m[k*9+k]; }
    for (usz i=0; i<n; i++) put_f64_le((nearbyint((double)ans[i]*100.0)/100.0), output, i*8);
    return (long)(n*8);
}
