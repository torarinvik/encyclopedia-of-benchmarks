module gross_profit_margin;

const double INVALID_RESULT = -1.0e300;

fn double gross_profit_margin(long* values, usz length) @export("gross_profit_margin") {
    if (values == null || length != 2) return INVALID_RESULT;
    long revenue = values[0];
    long cost = values[1];
    if (revenue < 1 || revenue > 1000000 || cost < 0 || cost > 1000000) return INVALID_RESULT;
    return ((double)revenue - (double)cost) / (double)revenue;
}
