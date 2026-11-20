module weak_heapsort;

const usz MAX_VALUES = 256;
const usz MAX_INPUT_LENGTH = 258;

fn usz distinguished_ancestor(usz node, bool* reverse) {
    while ((node % 2 == 1) == reverse[node / 2]) node /= 2;
    return node / 2;
}

fn void weak_join(long* values, bool* reverse, usz ancestor, usz node) {
    if (values[ancestor] < values[node]) {
        long temporary = values[ancestor];
        values[ancestor] = values[node];
        values[node] = temporary;
        reverse[node] = !reverse[node];
    }
}

fn void sift_down(long* values, bool* reverse, usz active_size) {
    usz node = 1;
    if (reverse[0]) node = 0;
    if (node >= active_size) return;
    while (true) {
        usz child = 2 * node;
        if (reverse[node]) child++;
        if (child >= active_size) break;
        node = child;
    }
    while (node != 0) {
        weak_join(values, reverse, 0, node);
        node /= 2;
    }
}

fn long weak_heapsort(long* input, usz length) @export("weak_heapsort") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > (long)MAX_VALUES) return -1;
    usz count = (usz)raw_count;
    if (length != count + 1) return -1;

    long[MAX_VALUES] values = zeroed;
    bool[MAX_VALUES] reverse = zeroed;
    for (usz i = 0; i < count; i++) {
        long value = input[i + 1];
        if (value < -1000 || value > 1000) return -1;
        values[i] = value;
    }

    for (usz next = count; next > 1; next--) {
        usz node = next - 1;
        usz ancestor = distinguished_ancestor(node, &reverse[0]);
        weak_join(&values[0], &reverse[0], ancestor, node);
    }
    for (usz end = count; end > 1; end--) {
        long temporary = values[0];
        values[0] = values[end - 1];
        values[end - 1] = temporary;
        sift_down(&values[0], &reverse[0], end - 1);
    }

    long checksum = 0;
    for (usz i = 0; i < count; i++) checksum += (long)(i + 1) * (values[i] + 1001);
    return checksum;
}
