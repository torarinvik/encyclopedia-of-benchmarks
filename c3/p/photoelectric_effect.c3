module photoelectric_effect;

const double PLANCK_EV = 4.1357e-15;
const double INVALID_RESULT = -1.0e300;

fn double photoelectric_effect(long* values, usz length) @export("photoelectric_effect") {
    if (values == null || length != 2) return INVALID_RESULT;
    long frequency = values[0];
    long work_function = values[1];
    if (frequency < 0 || frequency > 1000000000000000000 || work_function < 0 || work_function > 1000) return INVALID_RESULT;
    double photon_energy = PLANCK_EV * (double)frequency;
    double energy_difference = photon_energy - (double)work_function;
    return energy_difference > 0.0 ? energy_difference : 0.0;
}
