module ncr_combinations;

const double INVALID_RESULT = -1.0e300;

fn double ncr_combinations(double total, double choose) @export("ncr_combinations") {
    if (total != total || choose != choose || total < 0.0 || total > 20.0 ||
        choose < 0.0 || choose > 12.0 || choose != (double)(long)choose) {
        return INVALID_RESULT;
    }

    long count = (long)choose;
    double numerator = 1.0;
    for (long index = 0; index < count; index++) {
        numerator *= total - (double)index;
    }
    double denominator = 1.0;
    for (long factor = 2; factor <= count; factor++) {
        denominator *= (double)factor;
    }
    return numerator / denominator;
}
