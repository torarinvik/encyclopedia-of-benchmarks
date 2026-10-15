module npv;
extern fn double pow(double base, double exponent);
const double INVALID = -1e300;
fn double npv(long* input, usz length) @export("npv") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 1000) return INVALID;
    usz n = (usz)input[0]; if (length != n + 2) return INVALID;
    for (usz t=0;t<n;t++) if (input[t+2] < -1000000 || input[t+2] > 1000000) return INVALID;
    double rate=(double)input[1]/10000.0, total=0.0;
    for (usz t=0;t<n;t++) { double term=(double)input[t+2]/pow(1.0+rate,(double)t); total+=term; }
    return total;
}
