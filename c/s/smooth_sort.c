#include <stddef.h>
#include <stdint.h>

#define MAX_N 512u
#define MAX_PARSEABLE_INPUT_LENGTH 514u
#define MAX_VALUE INT64_C(1000000)
#define OFFSET INT64_C(1000001)

static const size_t LEONARDO[16] = {
    1u, 1u, 3u, 5u, 9u, 15u, 25u, 41u,
    67u, 109u, 177u, 287u, 465u, 753u, 1219u, 1973u
};

static unsigned trailing_zeros_u64(uint64_t value)
{
    unsigned count = 0u;
    while ((value & UINT64_C(1)) == 0u) {
        value >>= 1u;
        ++count;
    }
    return count;
}

static void sift(int64_t *values, size_t order, size_t root)
{
    const int64_t value = values[root];
    while (order > 1u) {
        const size_t right = root - 1u;
        const size_t left = root - 1u - LEONARDO[order - 2u];
        if (!(value < values[left]) && !(value < values[right])) break;
        if (!(values[left] < values[right])) {
            values[root] = values[left];
            root = left;
            --order;
        } else {
            values[root] = values[right];
            root = right;
            order -= 2u;
        }
    }
    values[root] = value;
}

static void trinkle(int64_t *values, uint64_t p, size_t order, size_t root, int trusty)
{
    const int64_t value = values[root];
    while (p != UINT64_C(1)) {
        const size_t stepson = root - LEONARDO[order];
        if (!(value < values[stepson])) break;
        if (!trusty && order > 1u) {
            const size_t right = root - 1u;
            const size_t left = root - 1u - LEONARDO[order - 2u];
            if (!(values[right] < values[stepson]) || !(values[left] < values[stepson])) break;
        }
        values[root] = values[stepson];
        root = stepson;
        const uint64_t mask = p & ~UINT64_C(1);
        const unsigned shift = trailing_zeros_u64(mask);
        p >>= shift;
        order += (size_t)shift;
        trusty = 0;
    }
    if (!trusty) {
        values[root] = value;
        sift(values, order, root);
    }
}

static void smoothsort(int64_t *values, size_t length)
{
    if (length < 2u) return;
    const size_t last = length - 1u;
    uint64_t p = UINT64_C(1);
    size_t pshift = 1u;
    size_t head = 0u;
    while (head < last) {
        if ((p & UINT64_C(3)) == UINT64_C(3)) {
            sift(values, pshift, head);
            p >>= 2u;
            pshift += 2u;
        } else {
            if (LEONARDO[pshift - 1u] >= last - head) trinkle(values, p, pshift, head, 0);
            else sift(values, pshift, head);
            if (pshift == 1u) {
                p <<= 1u;
                pshift = 0u;
            } else {
                p <<= pshift - 1u;
                pshift = 1u;
            }
        }
        p |= UINT64_C(1);
        ++head;
    }
    trinkle(values, p, pshift, head, 0);
    while (pshift != 1u || p != UINT64_C(1)) {
        if (pshift <= 1u) {
            const uint64_t mask = p & ~UINT64_C(1);
            const unsigned shift = trailing_zeros_u64(mask);
            p >>= shift;
            pshift += (size_t)shift;
        } else {
            p <<= 2u;
            p ^= UINT64_C(7);
            pshift -= 2u;
            trinkle(values, p >> 1u, pshift + 1u,
                    head - LEONARDO[pshift] - 1u, 1);
            trinkle(values, p, pshift, head - 1u, 1);
        }
        --head;
    }
}

int64_t smooth_sort_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1u || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_N) return -1;
    const size_t count = (size_t)input[0];
    if (length != count + 1u) return -1;

    int64_t values[MAX_N] = {0};
    for (size_t index = 0u; index < count; ++index) {
        const int64_t value = input[index + 1u];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        values[index] = value;
    }
    smoothsort(values, count);
    int64_t checksum = 0;
    for (size_t index = 0u; index < count; ++index)
        checksum += (int64_t)(index + 1u) * (values[index] + OFFSET);
    return checksum;
}
