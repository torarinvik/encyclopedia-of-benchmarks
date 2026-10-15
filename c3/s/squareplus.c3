module squareplus;

extern fn double sqrt(double value);

const double INVALID_RESULT = -1.0e300;

fn double squareplus(double x, double beta) @export("squareplus") {
    if (!(x >= -10000.0 && x <= 10000.0 && beta >= 0.25 && beta <= 10000.0)) return INVALID_RESULT;
    return (x + sqrt(x * x + beta)) / 2.0;
}
