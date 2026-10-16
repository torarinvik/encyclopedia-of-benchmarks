module debt_to_equity;

const double INVALID_RESULT = -1.0e300;

fn double debt_to_equity(long* values, usz length) @export("debt_to_equity") {
    if (values == null || length != 2) return INVALID_RESULT;
    long debt = values[0];
    long equity = values[1];
    if (debt < 0 || debt > 1000000 || equity < 1 || equity > 1000000) return INVALID_RESULT;
    return (double)debt / (double)equity;
}
