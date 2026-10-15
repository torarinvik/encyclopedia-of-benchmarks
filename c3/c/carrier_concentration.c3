module carrier_concentration;

const double INVALID_RESULT = -1.0e300;
extern fn double pow(double base, double exponent);

fn double carrier_concentration(long* values, usz length) @export("carrier_concentration") {
    if (values == null || length != 3) return INVALID_RESULT;
    long electron_conc = values[0];
    long hole_conc = values[1];
    long intrinsic_conc = values[2];
    if (electron_conc < 0 || electron_conc > 1000000 || hole_conc < 0 || hole_conc > 1000000 ||
        intrinsic_conc < 0 || intrinsic_conc > 1000000) return INVALID_RESULT;
    int zero_count = 0;
    if (electron_conc == 0) zero_count++;
    if (hole_conc == 0) zero_count++;
    if (intrinsic_conc == 0) zero_count++;
    if (zero_count != 1) return INVALID_RESULT;
    if (electron_conc == 0) return (double)(intrinsic_conc * intrinsic_conc) / (double)hole_conc;
    if (hole_conc == 0) return (double)(intrinsic_conc * intrinsic_conc) / (double)electron_conc;
    return pow((double)(electron_conc * hole_conc), 0.5);
}
