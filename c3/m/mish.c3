module mish;

extern fn double exp(double value);
extern fn double log(double value);
extern fn double tanh(double value);

const double INVALID_RESULT = -1.0e300;

fn double mish(double x) @export("mish") {
    if (!(x >= -20.0 && x <= 20.0)) return INVALID_RESULT;
    double softplus = log(1.0 + exp(x));
    return x * tanh(softplus);
}
