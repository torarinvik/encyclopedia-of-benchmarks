module k_folds;

fn long k_folds(long* values, usz length) @export("k_folds") {
    if (values == null || length != 2) return -1;
    long sample_count = values[0], fold_count = values[1];
    if (sample_count < 1 || sample_count > 12 || fold_count < 1 || fold_count > 12) return -1;
    long width = (sample_count + fold_count - 1) / fold_count;
    ulong result = (ulong)sample_count << 48;
    for (int index = 0; index < (int)sample_count; index++) {
        ulong fold = (ulong)(index + width) / (ulong)width;
        result |= fold << (4 * index);
    }
    return (long)result;
}
