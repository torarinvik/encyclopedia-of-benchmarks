module electric_conductivity;

const double ELECTRON_CHARGE = 1.6021e-19;
const double INVALID_RESULT = -1.0e300;

fn double electric_conductivity(long* values, usz length) @export("electric_conductivity") {
    if (values == null || length != 3) return INVALID_RESULT;
    long conductivity = values[0];
    long electron_conc = values[1];
    long mobility = values[2];
    if (conductivity < 0 || conductivity > 1000 || electron_conc < 0 || electron_conc > 1000 || mobility < 0 || mobility > 1000) return INVALID_RESULT;
    int zeros = 0;
    if (conductivity == 0) zeros++;
    if (electron_conc == 0) zeros++;
    if (mobility == 0) zeros++;
    if (zeros != 1) return INVALID_RESULT;
    if (conductivity == 0) return (double)mobility * (double)electron_conc * ELECTRON_CHARGE;
    if (electron_conc == 0) return (double)conductivity / ((double)mobility * ELECTRON_CHARGE);
    return (double)conductivity / ((double)electron_conc * ELECTRON_CHARGE);
}
