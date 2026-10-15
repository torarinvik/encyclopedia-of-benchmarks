module npv_sensitivity;
extern fn double pow(double base, double exponent);
fn void put_f64_le(double value, char* output, usz offset) {
    ulong bits = @bitcast(ulong, value);
    for (usz b = 0; b < 8; b++) { output[offset+b] = (char)(bits & 255); bits >>= 8; }
}
fn long npv_sensitivity(long* input, usz length, char* output, usz capacity) @export("npv_sensitivity") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    usz n=(usz)input[0], rates=(usz)input[1]; if (length != 2+n+rates) return -1;
    for (usz t=0;t<n;t++) if (input[2+t] < -1000000 || input[2+t] > 1000000) return -1;
    for (usz r=0;r<rates;r++) if (input[2+n+r] < 0 || input[2+n+r] > 1000) return -1;
    if (capacity < rates*8 || (rates > 0 && output == null)) return -2;
    for (usz r=0;r<rates;r++) {
        double rate=(double)input[2+n+r]/10000.0, total=0.0;
        for (usz t=0;t<n;t++) { double term=(double)input[2+t]/pow(1.0+rate,(double)t); total+=term; }
        put_f64_le(total,output,r*8);
    }
    return (long)(rates*8);
}
