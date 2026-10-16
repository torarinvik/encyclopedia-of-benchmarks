module return_on_investment;

const double INVALID_RESULT = -1.0e300;

fn double return_on_investment(long* values, usz length) @export("return_on_investment") {
    if (values == null || length != 2) return INVALID_RESULT;
    long gain = values[0];
    long cost = values[1];
    if (gain < -1000000 || gain > 1000000 || cost < 1 || cost > 1000000) return INVALID_RESULT;
    return ((double)gain - (double)cost) / (double)cost;
}
