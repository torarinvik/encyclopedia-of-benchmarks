module ohms_law;

fn double ohms_law(double voltage, double current, double resistance) @export("ohms_law") {
    if (voltage != voltage || current != current || resistance != resistance ||
        voltage < -1000.0 || voltage > 1000.0 || current < -1000.0 || current > 1000.0 ||
        resistance < 0.0 || resistance > 1000.0 ||
        voltage != (double)(long)voltage || current != (double)(long)current || resistance != (double)(long)resistance) return -1e300;
    int zeros = 0;
    if (voltage == 0.0) zeros++;
    if (current == 0.0) zeros++;
    if (resistance == 0.0) zeros++;
    if (zeros != 1) return -1e300;
    if (voltage == 0.0) return current * resistance;
    if (current == 0.0) return voltage / resistance;
    return voltage / current;
}
