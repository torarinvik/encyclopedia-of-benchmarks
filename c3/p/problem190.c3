module problem190;

extern fn double pow(double base, double exponent);
const long MAX_N = 15;

fn long problem190(long n) @export("problem190") {
    if (n < 0 || n > MAX_N) return -1;
    long total = 0;
    for (long m = 2; m <= n; m++) {
        double x1 = 2.0 / (m + 1).double();
        double product = 1.0;
        for (long i = 1; i <= m; i++) {
            double xi = i.double() * x1;
            product *= pow(xi, i.double());
        }
        total += product.long();
    }
    return total;
}
