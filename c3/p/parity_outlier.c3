module parity_outlier;

fn long parity_outlier(long* values, usz length) @export("parity_outlier") {
    if (values == null || length < 1) return -1;
    if (values[0] < 3 || values[0] > 65 || (values[0] & 1) == 0) return -1;
    usz count = (usz)values[0];
    if (length != count + 1) return -1;
    usz evens = 0;
    usz odds = 0;
    long even_value = 0;
    long odd_value = 0;
    for (usz i = 0; i < count; i++) {
        long value = values[i + 1];
        if (value < 0 || value > 2147483647) return -1;
        if ((value & 1) == 0) { evens++; even_value = value; }
        else { odds++; odd_value = value; }
    }
    if (evens == 1 && odds >= 2) return even_value;
    if (odds == 1 && evens >= 2) return odd_value;
    return -1;
}
