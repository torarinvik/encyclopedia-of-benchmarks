module relativistic_kinetic_energy;

extern fn double sqrt(double value);

const long SPEED_OF_LIGHT = 299792458;
const double INVALID_RESULT = -1.0e300;

fn double relativistic_kinetic_energy(long* values, usz length) @export("relativistic_kinetic_energy") {
    if (values == null || length != 2) return INVALID_RESULT;
    long mass = values[0];
    long velocity = values[1];
    if (mass < 0 || mass > 1000000 || velocity < -(SPEED_OF_LIGHT - 1) || velocity > SPEED_OF_LIGHT - 1)
        return INVALID_RESULT;
    double gamma = 1.0 / sqrt(1.0 - ((double)(velocity * velocity) / (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT)));
    return (gamma - 1.0) * (double)mass * (double)(SPEED_OF_LIGHT * SPEED_OF_LIGHT);
}
