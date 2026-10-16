module gamma;

const double INVALID_RESULT = -1.0e300;

fn double gamma_recursive_impl(double num) {
    if (num == 0.5) return sqrt(3.14159265358979323846);
    if (num == 1.0) return 1.0;
    return (num - 1.0) * gamma_recursive_impl(num - 1.0);
}

fn double gamma_recursive(double num) @export("gamma_recursive") {
    if (!(num >= 0.5 && num <= 20.0) || num * 2.0 != floor(num * 2.0)) return INVALID_RESULT;
    return gamma_recursive_impl(num);
}
