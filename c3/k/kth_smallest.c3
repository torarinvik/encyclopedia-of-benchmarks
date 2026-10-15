module kth_smallest;

const usz MAX_LENGTH = 256;

fn usz partition_values(int* values, usz low, usz high) {
    usz pivot = high;
    usz i = low;
    usz j = high - 1;
    while (true) {
        while (values[i] < values[pivot]) { i++; }
        while (j > 0 && values[j] > values[pivot]) { j--; }
        if (j == 0 || i >= j) { break; }
        if (values[i] == values[j]) {
            i++;
            j--;
        } else {
            int temporary = values[i];
            values[i] = values[j];
            values[j] = temporary;
        }
    }
    int temporary = values[i];
    values[i] = values[pivot];
    values[pivot] = temporary;
    return i;
}

// Select the one-based k-th value, following Rust's in-place quickselect.
fn long kth_smallest(long* input, usz length) @export("kth_smallest") {
    if (input == null || length < 3 || length > MAX_LENGTH + 2) { return -9223372036854775807L - 1; }
    long n_value = input[0];
    long k_value = input[1];
    if (n_value < 1 || n_value > (long)MAX_LENGTH || k_value < 1 || k_value > n_value ||
        length != (usz)n_value + 2) { return -9223372036854775807L - 1; }
    usz n = (usz)n_value;
    int[MAX_LENGTH] values;
    for (usz index = 0; index < n; index++) {
        long value = input[index + 2];
        if (value < -2147483648L || value > 2147483647L) { return -9223372036854775807L - 1; }
        values[index] = (int)value;
    }
    usz low = 0;
    usz high = n - 1;
    usz k = (usz)k_value;
    while (low < high) {
        usz pivot = partition_values(&values[0], low, high);
        usz pivot_rank = pivot - low + 1;
        if (k == pivot_rank) { return values[pivot]; }
        if (k < pivot_rank) {
            high = pivot - 1;
        } else {
            low = pivot + 1;
            k -= pivot_rank;
        }
    }
    return values[low];
}
