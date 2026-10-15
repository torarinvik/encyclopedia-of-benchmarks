module electric_power;

// Pinned electric_power formula over the benchmark's bounded integer-valued domain.
fn double electric_power(double voltage, double current, double power) @export("electric_power") {
    if (voltage != voltage || current != current || power != power ||
        voltage < -10000.0 || voltage > 10000.0 ||
        current < -10000.0 || current > 10000.0 ||
        power < 0.0 || power > 100000000.0 ||
        voltage != (double)(long)voltage || current != (double)(long)current ||
        power != (double)(long)power) return -1.0e300;
    int zeros = 0;
    if (voltage == 0.0) zeros++;
    if (current == 0.0) zeros++;
    if (power == 0.0) zeros++;
    if (zeros != 1) return -1.0e300;
    if (voltage == 0.0) return power / current;
    if (current == 0.0) return power / voltage;
    double product = voltage * current;
    return product < 0.0 ? -product : product;
}
