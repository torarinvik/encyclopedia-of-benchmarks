module problem124;

fn long problem124(long n_max, long k) @export("problem124") {
    if (n_max < 1 || n_max > 100000 || k < 1 || k > n_max) return -1;
    int n = (int)n_max;
    uint[100001] radicals;
    uint[100001] counts = {0};
    for (int i = 1; i <= n; i++) radicals[i] = 1;
    for (int p = 2; p <= n; p++) {
        if (radicals[p] == 1) {
            for (int multiple = p; multiple <= n; multiple += p) radicals[multiple] *= (uint)p;
        }
    }
    for (int i = 1; i <= n; i++) counts[radicals[i]]++;
    uint remaining = (uint)k;
    for (int rad = 1; rad <= n; rad++) {
        if (remaining > counts[rad]) { remaining -= counts[rad]; continue; }
        for (int value = 1; value <= n; value++) {
            if (radicals[value] == (uint)rad) {
                remaining--;
                if (remaining == 0) return value;
            }
        }
    }
    return -1;
}
