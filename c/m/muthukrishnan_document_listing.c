#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_DOCS 8
#define MAX_QUERIES 16
#define MAX_INPUT 68
#define MAX_OUTPUT 144
#define LEVELS 6

static size_t rmq(size_t lo, size_t hi, const int64_t previous[MAX_N],
                  const int table[LEVELS][MAX_N], const int logs[MAX_N + 1])
{
    const size_t length = hi - lo + 1;
    const int level = logs[length];
    const size_t width = (size_t)1 << level;
    int left = table[level][lo];
    int right = table[level][hi - width + 1];
    if (previous[left] < previous[right] ||
        (previous[left] == previous[right] && left < right)) return (size_t)left;
    return (size_t)right;
}

static void report(size_t lo, size_t hi, size_t query_lo,
                   const int64_t previous[MAX_N], const int64_t da[MAX_N],
                   const int table[LEVELS][MAX_N], const int logs[MAX_N + 1],
                   size_t ranks[MAX_DOCS], uint8_t found_docs[MAX_DOCS], size_t *count)
{
    if (lo > hi) return;
    const size_t index = rmq(lo, hi, previous, table, logs);
    if (previous[index] >= (int64_t)query_lo) return;
    ranks[*count] = index;
    found_docs[*count] = (uint8_t)da[index];
    ++*count;
    if (index > lo)
        report(lo, index - 1, query_lo, previous, da, table, logs, ranks, found_docs, count);
    if (index < hi)
        report(index + 1, hi, query_lo, previous, da, table, logs, ranks, found_docs, count);
}

int64_t muthukrishnan_document_listing(const int64_t *values, size_t length,
                                      uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n_value = values[0], docs_value = values[1], q_value = values[2];
    if (n_value < 1 || n_value > MAX_N || docs_value < 1 || docs_value > MAX_DOCS ||
        q_value < 1 || q_value > MAX_QUERIES) return -1;
    const size_t n = (size_t)n_value, docs = (size_t)docs_value, q = (size_t)q_value;
    if (length != 3 + n + 2 * q) return -1;

    int64_t da[MAX_N], previous[MAX_N], last[MAX_DOCS];
    for (size_t doc = 0; doc < docs; ++doc) last[doc] = -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t document = values[3 + i];
        if (document < 0 || document >= docs_value) return -1;
        da[i] = document;
        previous[i] = last[(size_t)document];
        last[(size_t)document] = (int64_t)i;
    }
    for (size_t i = 0; i < q; ++i) {
        const int64_t lo = values[3 + n + 2 * i], hi = values[4 + n + 2 * i];
        if (lo < 0 || hi < lo || hi >= n_value) return -1;
    }

    int logs[MAX_N + 1] = {0};
    for (size_t length_value = 2; length_value <= n; ++length_value)
        logs[length_value] = logs[length_value / 2] + 1;
    int table[LEVELS][MAX_N];
    for (size_t i = 0; i < n; ++i) table[0][i] = (int)i;
    const int level_count = logs[n] + 1;
    for (int level = 1; level < level_count; ++level) {
        const size_t width = (size_t)1 << level, half = width >> 1;
        for (size_t start = 0; start + width <= n; ++start) {
            const int left = table[level - 1][start];
            const int right = table[level - 1][start + half];
            table[level][start] =
                previous[left] < previous[right] ||
                (previous[left] == previous[right] && left < right) ? left : right;
        }
    }

    uint8_t staged[MAX_OUTPUT];
    size_t written = 0;
    for (size_t query = 0; query < q; ++query) {
        const size_t lo = (size_t)values[3 + n + 2 * query];
        const size_t hi = (size_t)values[4 + n + 2 * query];
        const size_t count_at = written++;
        size_t ranks[MAX_DOCS];
        uint8_t found_docs[MAX_DOCS];
        size_t count = 0;
        report(lo, hi, lo, previous, da, table, logs, ranks, found_docs, &count);
        for (size_t i = 1; i < count; ++i) {
            const size_t rank = ranks[i];
            const uint8_t document = found_docs[i];
            size_t j = i;
            while (j > 0 && ranks[j - 1] > rank) {
                ranks[j] = ranks[j - 1];
                found_docs[j] = found_docs[j - 1];
                --j;
            }
            ranks[j] = rank;
            found_docs[j] = document;
        }
        staged[count_at] = (uint8_t)count;
        for (size_t i = 0; i < count; ++i) staged[written++] = found_docs[i];
    }
    if (written > MAX_OUTPUT) return -1;
    if (output == NULL || output_capacity < written) return -2;
    for (size_t i = 0; i < written; ++i) output[i] = staged[i];
    return (int64_t)written;
}
