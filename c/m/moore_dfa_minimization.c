#include <stddef.h>
#include <stdint.h>

enum { MAX_STATES = 8, MAX_ALPHABET = 3 };

int64_t moore_dfa_minimization(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > 29) return -1;
    const int64_t n64 = input[0], alphabet64 = input[1], start64 = input[2], accepting = input[3];
    if (n64 < 1 || n64 > MAX_STATES || alphabet64 < 1 || alphabet64 > MAX_ALPHABET
        || start64 < 0 || start64 >= n64 || accepting < 0 || accepting >= (INT64_C(1) << n64)) return -1;
    const size_t n = (size_t)n64, alphabet = (size_t)alphabet64;
    if (length != 4 + n * alphabet) return -1;
    int transition[MAX_STATES][MAX_ALPHABET] = {{0}};
    for (size_t s = 0; s < n; ++s) for (size_t a = 0; a < alphabet; ++a) {
        const int64_t target = input[4 + s * alphabet + a];
        if (target < 0 || target >= n64) return -1;
        transition[s][a] = (int)target;
    }

    int labels[MAX_STATES] = {0}, refined[MAX_STATES] = {0};
    int acceptance_id[2] = {-1, -1}, classes = 0;
    for (size_t s = 0; s < n; ++s) {
        const int bit = (int)((accepting >> s) & 1);
        if (acceptance_id[bit] < 0) acceptance_id[bit] = classes++;
        labels[s] = acceptance_id[bit];
    }

    int rounds = 0;
    for (;;) {
        int signatures[MAX_STATES] = {0};
        int signature_count = 0;
        for (size_t s = 0; s < n; ++s) {
            int signature = labels[s];
            for (size_t a = 0; a < alphabet; ++a)
                signature = signature * MAX_STATES + labels[transition[s][a]];
            int id = 0;
            while (id < signature_count && signatures[id] != signature) ++id;
            if (id == signature_count) signatures[signature_count++] = signature;
            refined[s] = id;
        }
        int changed = 0;
        for (size_t s = 0; s < n; ++s) if (refined[s] != labels[s]) changed = 1;
        if (!changed) { classes = signature_count; break; }
        for (size_t s = 0; s < n; ++s) labels[s] = refined[s];
        classes = signature_count;
        ++rounds;
    }

    int64_t packed = ((int64_t)classes << 28) | ((int64_t)rounds << 24);
    for (size_t s = 0; s < n; ++s) packed |= (int64_t)labels[s] << (3 * s);
    return packed;
}
