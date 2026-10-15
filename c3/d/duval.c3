module duval;

// Least cyclic shift index using Duval's linear-time scan.
fn long duval(long* values, usz length) @export("duval") {
    if (length > 4096) return -1;
    if (length == 0) return 0;
    if (values == null) return -1;
    for (usz index = 0; index < length; index++) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }

    usz i = 0, answer = 0;
    while (i < length) {
        answer = i;
        usz j = i + 1, k = i;
        while (j < 2 * length && values[j % length] >= values[k % length]) {
            if (values[k % length] < values[j % length]) k = i;
            else k += 1;
            j += 1;
        }
        while (i <= k) i += j - k;
    }
    return (long)answer;
}
