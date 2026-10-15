module babylonian_method;

fn double babylonian_method(double input) @export("babylonian_method") {
    if (!(input >= 2.0 && input <= 999999.0)) return -1.0;
    long radicand = (long)input;
    if ((double)radicand != input) return -1.0;
    long i = 1;
    while (i * i <= radicand) { i++; }
    i--;
    if (i * i == radicand) return -1.0;
    double x0 = (double)i;
    return (input / x0 + x0) / 2.0;
}
