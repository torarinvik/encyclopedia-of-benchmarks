module optimal_file_merging;

const long MAX_SIZE = 1000000;

fn long optimal_file_merging(long* values, usz length) @export("optimal_file_merging") {
    if (values == null || length < 1 || length > 33) return -1;
    long count = values[0];
    if (count < 0 || count > 32 || length != (usz)count + 1) return -1;
    long files[32];
    for (usz i = 0; i < (usz)count; i++) {
        if (values[i + 1] < 0 || values[i + 1] > MAX_SIZE) return -1;
        files[i] = values[i + 1];
    }
    usz n = (usz)count;
    long total = 0;
    while (n > 1) {
        usz a = 0, b = 1;
        if (files[b] < files[a]) { usz t = a; a = b; b = t; }
        for (usz i = 2; i < n; i++) {
            if (files[i] < files[a]) { b = a; a = i; }
            else if (files[i] < files[b]) b = i;
        }
        long merged = files[a] + files[b]; total += merged;
        if (a > b) { usz t = a; a = b; b = t; }
        files[a] = merged; files[b] = files[n - 1]; n--;
    }
    return total;
}
