#include <stddef.h>
#include <stdint.h>

#define MODULUS INT64_C(998244353)
#define MAX_N ((size_t)16)
#define MAX_Q ((size_t)32)
#define MAX_LENGTH ((size_t)210)
#define MAX_SEEN ((size_t)48)

typedef struct { int64_t priority, a, b; } Record;

int64_t point_set_range_sort_range_composite(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_N || input[1] < 1 || input[1] > (int64_t)MAX_Q) return -1;
    const size_t n = (size_t)input[0], q = (size_t)input[1];
    if (length < 2 + 3 * n) return -1;
    Record records[MAX_N];
    int64_t seen[MAX_SEEN];
    size_t seen_count = 0, cursor = 2;
    for (size_t i = 0; i < n; ++i) {
        const int64_t p = input[cursor++], a = input[cursor++], b = input[cursor++];
        if (p < 0 || p > INT64_C(1000000000) || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
        for (size_t j = 0; j < seen_count; ++j) if (seen[j] == p) return -1;
        seen[seen_count++] = p;
        records[i] = (Record){p, a, b};
    }

    int64_t checksum = 0, query_number = 0;
    for (size_t operation = 0; operation < q; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (length - cursor < 4) return -1;
            const int64_t index = input[cursor++], p = input[cursor++], a = input[cursor++], b = input[cursor++];
            if (index < 0 || index >= (int64_t)n || p < 0 || p > INT64_C(1000000000) || a < 1 || a >= MODULUS || b < 0 || b >= MODULUS) return -1;
            for (size_t j = 0; j < seen_count; ++j) if (seen[j] == p) return -1;
            seen[seen_count++] = p;
            records[(size_t)index] = (Record){p, a, b};
        } else if (opcode == 1) {
            if (length - cursor < 3) return -1;
            const int64_t left = input[cursor++], right = input[cursor++], x = input[cursor++];
            if (left < 0 || left >= right || right > (int64_t)n || x < 0 || x >= MODULUS) return -1;
            int64_t answer = x;
            for (size_t i = (size_t)left; i < (size_t)right; ++i)
                answer = (records[i].a * answer + records[i].b) % MODULUS;
            ++query_number;
            checksum = (checksum + query_number * answer) % MODULUS;
        } else if (opcode == 2 || opcode == 3) {
            if (length - cursor < 2) return -1;
            const int64_t left = input[cursor++], right = input[cursor++];
            if (left < 0 || left >= right || right > (int64_t)n) return -1;
            for (size_t i = (size_t)left + 1; i < (size_t)right; ++i) {
                Record item = records[i];
                size_t j = i;
                while (j > (size_t)left && (opcode == 2 ? records[j - 1].priority > item.priority : records[j - 1].priority < item.priority)) {
                    records[j] = records[j - 1];
                    --j;
                }
                records[j] = item;
            }
        } else return -1;
    }
    return cursor == length ? checksum : -1;
}
