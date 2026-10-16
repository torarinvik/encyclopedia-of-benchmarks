module federated_averaging;
fn double federated_averaging(long *input, usz length) @export("federated_averaging") {
    if (input == null || length < 3 || length > 17) return -1.0e300;
    long clients = input[0];
    if (clients < 1 || clients > 8 || length != 1 + 2 * (usz)clients) return -1.0e300;
    double total = 0.0;
    for (long i = 0; i < clients; i++) {
        long weight = input[1 + i];
        if (weight < 0 || weight > 1000) return -1.0e300;
        total += (double)weight;
    }
    if (total <= 0.0) return -1.0e300;
    double result = 0.0;
    for (long i = 0; i < clients; i++) {
        long value = input[1 + clients + i];
        if (value < -1000 || value > 1000) return -1.0e300;
        double normalized = (double)input[1 + i] / total;
        result += normalized * (double)value;
    }
    return result;
}
