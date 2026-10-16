module sparse_categorical_cross_entropy;
extern fn double log(double value);
extern fn double log1p(double value);
extern fn double fabs(double value);
const double INVALID_RESULT=-1.0e300; const double SCALE=1000000.0;
fn double sparse_categorical_cross_entropy(long* values, usz length) @export("sparse_categorical_cross_entropy") {
    if (values == null || length < 2) return INVALID_RESULT;
    long batch = values[0], classes = values[1];
    if (batch < 1 || batch > 32 || classes < 1 || classes > 32 || length != 2 + (usz)batch + (usz)batch * (usz)classes) return INVALID_RESULT;
    for (usz r = 0; r < (usz)batch; r++) { long label = values[2 + r], sum = 0; if (label < 0 || label >= classes) return INVALID_RESULT; for (usz col = 0; col < (usz)classes; col++) { long x = values[2 + (usz)batch + r * (usz)classes + col]; if (x < 0 || x > 1000000) return INVALID_RESULT; sum += x; } if (sum != 1000000) return INVALID_RESULT; }
    double total = 0.0; for (usz r = 0; r < (usz)batch; r++) { double p = (double)values[2 + (usz)batch + r * (usz)classes + (usz)values[2 + r]] / SCALE; if (p < 1e-15) p = 1e-15; total -= log(p); } return total;
}
