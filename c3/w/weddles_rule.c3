module weddles_rule;

const long MAX_PANELS = 64;
const long MAX_STEP_NANOUNITS = 1000000000;
const long MAX_SAMPLE_MICRO = 1000000;
const double INVALID_RESULT = -1.0e300;

fn double weddles_rule_impl(long* values, usz length) {
    if (values == null || length < 9 || length > 387) return INVALID_RESULT;
    long panels = values[0];
    long step_nanounits = values[1];
    if (panels < 1 || panels > MAX_PANELS || length != usz(6 * panels + 3) ||
        step_nanounits < -MAX_STEP_NANOUNITS || step_nanounits > MAX_STEP_NANOUNITS) return INVALID_RESULT;

    long sample_count = 6 * panels + 1;
    double weighted_sum = 0.0;
    for (long index = 1; index + 1 < sample_count; index += 1) {
        long sample_micro = values[index + 2];
        if (sample_micro < -MAX_SAMPLE_MICRO || sample_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        long weight;
        if (index % 2 == 0 && index % 3 != 0) weight = 1;
        else if (index % 2 != 0 && index % 3 != 0) weight = 5;
        else if (index % 6 == 0) weight = 2;
        else weight = 6;
        weighted_sum += (double)weight * ((double)sample_micro / 1000000.0);
    }
    long first_micro = values[2];
    long last_micro = values[sample_count + 1];
    if (first_micro < -MAX_SAMPLE_MICRO || first_micro > MAX_SAMPLE_MICRO ||
        last_micro < -MAX_SAMPLE_MICRO || last_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
    double step_size = (double)step_nanounits / 1000000000.0;
    return 0.3 * step_size * (weighted_sum + (double)first_micro / 1000000.0 + (double)last_micro / 1000000.0);
}

fn double weddles_rule(long* values, usz length) @export("weddles_rule") {
    return weddles_rule_impl(values, length);
}
