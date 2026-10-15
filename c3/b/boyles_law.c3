module boyles_law;

const double INVALID_RESULT = -1.0e300;

fn long rounded_milli(long numerator, long denominator) {
    long scaled = numerator * 1000;
    long quotient = scaled / denominator;
    long remainder = scaled % denominator;
    if (2 * remainder > denominator || (2 * remainder == denominator && quotient % 2 != 0)) quotient += 1;
    return quotient;
}

fn double boyles_law(long* values, usz length) @export("boyles_law") {
    if (values == null || length != 4) return INVALID_RESULT;
    long target = values[0], a = values[1], b = values[2], c = values[3];
    if (target < 0 || target > 3 || a < 1 || a > 1000 || b < 1 || b > 1000 || c < 1 || c > 1000) return INVALID_RESULT;
    long numerator, denominator;
    if (target == 0) { numerator = c * a; denominator = b; }
    else if (target == 1) { numerator = b * a; denominator = c; }
    else if (target == 2) { numerator = c * b; denominator = a; }
    else { numerator = c * a; denominator = b; }
    return (double)rounded_milli(numerator, denominator) / 1000.0;
}
