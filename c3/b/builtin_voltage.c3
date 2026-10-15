module builtin_voltage;

extern fn double log(double value);
const double BOLTZMANN = 1.380649e-23;
const double ELECTRON_VOLT = 1.602176634e-19;
const double INVALID_RESULT = -1.0e300;

fn double builtin_voltage(long* values, usz length) @export("builtin_voltage") {
    if (values == null || length != 3) return INVALID_RESULT;
    long donor = values[0];
    long acceptor = values[1];
    long intrinsic = values[2];
    if (donor < 1 || donor > 1000 || acceptor < 1 || acceptor > 1000 || intrinsic < 1 || intrinsic > 1000 ||
        donor <= intrinsic || acceptor <= intrinsic) return INVALID_RESULT;
    double ratio = ((double)donor * (double)acceptor) / ((double)intrinsic * (double)intrinsic);
    return BOLTZMANN * 300.0 * log(ratio) / ELECTRON_VOLT;
}
