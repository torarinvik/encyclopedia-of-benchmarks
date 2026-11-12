#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 24, MAX_RUNS = 144 };

typedef struct { int period, left, right; } Run;

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t runenumerate(const int64_t *input, size_t length,
                     uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_N + 1) return -1;
    int64_t n_value = input[0];
    if (n_value < 1 || n_value > MAX_N || length != (size_t)n_value + 1) return -1;
    int n = (int)n_value;
    int text[MAX_N];
    for (int i = 0; i < n; ++i) {
        if (input[i + 1] < 0 || input[i + 1] >= 26) return -1;
        text[i] = (int)input[i + 1];
    }
    if (output == NULL) return -2;

    int lcp[MAX_N + 1][MAX_N + 1] = {{0}};
    for (int i = n - 1; i >= 0; --i)
        for (int j = n - 1; j > i; --j)
            if (text[i] == text[j]) lcp[i][j] = 1 + lcp[i + 1][j + 1];

    Run runs[MAX_RUNS];
    int count = 0;
    for (int period = 1; period <= n / 2; ++period) {
        int i = period;
        while (i < n) {
            if (text[i] != text[i - period]) { ++i; continue; }
            int first = i;
            while (i < n && text[i] == text[i - period]) ++i;
            int left = first - period;
            int right = i;
            if (right - left < 2 * period) continue;
            int minimal = 1;
            for (int smaller = 1; smaller < period; ++smaller)
                if (lcp[left][left + smaller] >= right - left - smaller) {
                    minimal = 0;
                    break;
                }
            if (minimal && count < MAX_RUNS)
                runs[count++] = (Run){period, left, right};
        }
    }
    for (int i = 1; i < count; ++i) {
        Run value = runs[i];
        int j = i;
        while (j > 0 && (runs[j - 1].period > value.period ||
               (runs[j - 1].period == value.period && runs[j - 1].left > value.left) ||
               (runs[j - 1].period == value.period && runs[j - 1].left == value.left &&
                runs[j - 1].right > value.right))) {
            runs[j] = runs[j - 1];
            --j;
        }
        runs[j] = value;
    }
    size_t needed = 8 + 24 * (size_t)count;
    if (capacity < needed) return -2;
    store_i64_le(output, 0, count);
    for (int i = 0; i < count; ++i) {
        size_t offset = 8 + 24 * (size_t)i;
        store_i64_le(output, offset, runs[i].period);
        store_i64_le(output, offset + 8, runs[i].left);
        store_i64_le(output, offset + 16, runs[i].right);
    }
    return (int64_t)needed;
}
