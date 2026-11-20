module moore_dfa_minimization;

fn long moore_dfa_minimization(long* input, usz length) @export("moore_dfa_minimization") {
    if (input == null || length < 4 || length > 29) return -1;
    long n64 = input[0], alphabet64 = input[1], start64 = input[2], accepting = input[3];
    if (n64 < 1 || n64 > 8 || alphabet64 < 1 || alphabet64 > 3 || start64 < 0 || start64 >= n64
        || accepting < 0 || accepting >= (1L << n64)) return -1;
    usz n = (usz)n64, alphabet = (usz)alphabet64;
    if (length != 4 + n * alphabet) return -1;
    int[8][3] transition = {{0}};
    for (usz s = 0; s < n; s++) for (usz a = 0; a < alphabet; a++) {
        long target = input[4 + s * alphabet + a];
        if (target < 0 || target >= n64) return -1;
        transition[s][a] = (int)target;
    }
    int[8] labels = {0}, refined = {0};
    int[2] acceptance_id = {-1, -1};
    int classes = 0;
    for (usz s = 0; s < n; s++) {
        int bit = (int)((accepting >> s) & 1);
        if (acceptance_id[bit] < 0) acceptance_id[bit] = classes++;
        labels[s] = acceptance_id[bit];
    }
    int rounds = 0;
    for (;;) {
        int[8] signatures = {0};
        int signature_count = 0;
        for (usz s = 0; s < n; s++) {
            int signature = labels[s];
            for (usz a = 0; a < alphabet; a++) signature = signature * 8 + labels[transition[s][a]];
            int id = 0;
            while (id < signature_count && signatures[id] != signature) id++;
            if (id == signature_count) signatures[signature_count++] = signature;
            refined[s] = id;
        }
        bool changed = false;
        for (usz s = 0; s < n; s++) if (refined[s] != labels[s]) changed = true;
        if (!changed) { classes = signature_count; break; }
        for (usz s = 0; s < n; s++) labels[s] = refined[s];
        classes = signature_count;
        rounds++;
    }
    long packed = ((long)classes << 28) | ((long)rounds << 24);
    for (usz s = 0; s < n; s++) packed |= (long)labels[s] << (3 * s);
    return packed;
}
