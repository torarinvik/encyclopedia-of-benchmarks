module problem686;

const long MAX_POSITION = 678910;
const double LOG10_2 = 0.30102999566398114;
const double LOWER_LIMIT = 0.08990511143939792;
const double UPPER_LIMIT = 0.09342168516223506;
const double ROUND_SCALE = 1000000000000000.0;

fn double rounded_decimal_part(long exponent) {
    double logarithm = LOG10_2 * (double)exponent;
    long integer_part = (long)logarithm;
    double difference = logarithm - (double)integer_part;
    double scaled = difference * ROUND_SCALE;
    long rounded = (long)scaled;
    double remainder = scaled - (double)rounded;
    if (remainder > 0.5 || (remainder == 0.5 && rounded % 2 != 0)) rounded++;
    return (double)rounded / ROUND_SCALE;
}

fn long problem686(long number) @export("problem686") {
    if (number < 1 || number > MAX_POSITION) return -1;
    long power_iterator = 90, position = 0, previous_power = 0;
    while (position < number) {
        double difference = rounded_decimal_part(power_iterator);
        if (difference >= UPPER_LIMIT) power_iterator += 93;
        else if (difference < LOWER_LIMIT) power_iterator += 196;
        else { previous_power = power_iterator; power_iterator += 196; position++; }
    }
    return previous_power;
}
