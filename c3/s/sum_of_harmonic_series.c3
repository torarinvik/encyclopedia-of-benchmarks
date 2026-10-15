module sum_of_harmonic_series;
extern fn double floor(double value);
const double INVALID_RESULT = -1.0e300;
fn double sum_of_harmonic_series(double first_term, double common_difference, double number_of_terms) @export("sum_of_harmonic_series") {
    if (first_term <= 0.0 || first_term > 1000.0 || common_difference < 0.0 || common_difference > 1000.0 ||
        number_of_terms < 1.0 || number_of_terms > 256.0 || floor(number_of_terms) != number_of_terms) return INVALID_RESULT;
    int count = (int)number_of_terms;
    double arithmetic_term = 1.0 / first_term;
    double sum = 0.0;
    for (int index = 0; index < count; index++) {
        sum += 1.0 / arithmetic_term;
        if (index + 1 < count) arithmetic_term += common_difference;
    }
    return sum;
}
