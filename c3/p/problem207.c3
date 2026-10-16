module problem207;

const double INVALID_RESULT = -1.0e300;
const double MIN_PROPORTION = 1.0e-5;
const double MAX_PROPORTION = 1.0;
const long MAX_PARTITIONS = 5000000;

fn bool is_power_of_two(long value) {
    return value > 0 && (value & (value - 1)) == 0;
}

fn double problem207(double max_proportion) @export("problem207") {
    if (max_proportion != max_proportion || max_proportion < MIN_PROPORTION ||
        max_proportion > MAX_PROPORTION) return INVALID_RESULT;
    long partitions = 0;
    long perfect_partitions = 0;
    while (partitions < MAX_PARTITIONS) {
        partitions++;
        long candidate = partitions * (partitions + 1);
        if (is_power_of_two(partitions + 1)) perfect_partitions++;
        if (perfect_partitions.double() / partitions.double() < max_proportion)
            return candidate.double();
    }
    return INVALID_RESULT;
}
