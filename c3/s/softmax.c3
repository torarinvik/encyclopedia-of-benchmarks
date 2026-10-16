module softmax;

extern fn double exp(double value);

fn long softmax(double* values, usz length, double* output, usz capacity) @export("softmax") {
    if (values == null || length < 1 || length > 64) return -1;
    for (usz i = 0; i < length; i++) {
        if (values[i] != values[i] || values[i] < -20.0 || values[i] > 20.0) return -1;
    }
    if (output == null || capacity < length) return -2;

    double total = 0.0;
    for (usz i = 0; i < length; i++) total += exp(values[i]);
    for (usz i = 0; i < length; i++) output[i] = exp(values[i]) / total;
    return (long)length;
}
