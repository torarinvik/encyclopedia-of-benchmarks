module ind_reactance;

const double PI = 3.14159265358979323846;
const double INVALID_RESULT = -1.0e300;

fn double ind_reactance(long* values, usz length) @export("ind_reactance") {
    if (values == null || length != 3) return INVALID_RESULT;
    long inductance = values[0];
    long frequency = values[1];
    long reactance = values[2];
    if (inductance < 0 || inductance > 1000 || frequency < 0 || frequency > 1000 || reactance < 0 || reactance > 1000) return INVALID_RESULT;
    int zeros = 0;
    if (inductance == 0) zeros++;
    if (frequency == 0) zeros++;
    if (reactance == 0) zeros++;
    if (zeros != 1) return INVALID_RESULT;
    if (inductance == 0) return (double)reactance / (2.0 * PI * (double)frequency);
    if (frequency == 0) return (double)reactance / (2.0 * PI * (double)inductance);
    return 2.0 * PI * (double)frequency * (double)inductance;
}
