#include <stddef.h>
#include <stdint.h>

#define MAX_N 256u
#define MAX_Q 256u
#define MAX_INPUT_LENGTH (4u + MAX_N + 3u * MAX_Q + 1u)
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_byte(uint64_t hash, uint8_t byte)
{
    return (hash ^ (uint64_t)byte) * FNV_PRIME;
}

static int query_before(size_t a, size_t b, const int32_t *lefts,
                       const int32_t *rights, size_t block_size)
{
    const int32_t block_a = lefts[a] / (int32_t)block_size;
    const int32_t block_b = lefts[b] / (int32_t)block_size;
    if (block_a != block_b) return block_a < block_b;
    if ((block_a & 1) != 0) return rights[a] < rights[b];
    return rights[a] > rights[b];
}

int64_t mos_algorithm(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4u || length > MAX_INPUT_LENGTH) return -1;
    const int64_t operation64 = input[0];
    const int64_t n64 = input[1];
    const int64_t q64 = input[2];
    const int64_t target64 = input[3];
    if ((operation64 != 0 && operation64 != 1) || n64 < 1 || n64 > (int64_t)MAX_N
        || q64 < 0 || q64 > (int64_t)MAX_Q || target64 < -1000000 || target64 > 1000000
        || length != 4u + (size_t)n64 + 3u * (size_t)q64) return -1;
    const size_t n = (size_t)n64;
    const size_t q = (size_t)q64;
    const int32_t target = (int32_t)target64;

    int32_t values[MAX_N];
    for (size_t index = 0; index < n; ++index) {
        const int64_t value = input[4u + index];
        if (value < -1000000 || value > 1000000) return -1;
        values[index] = (int32_t)value;
    }

    int32_t lefts[MAX_Q], rights[MAX_Q], indices[MAX_Q];
    size_t order[MAX_Q];
    uint8_t seen[MAX_Q] = {0};
    const size_t query_offset = 4u + n;
    for (size_t query = 0; query < q; ++query) {
        const int64_t left = input[query_offset + 3u * query];
        const int64_t right = input[query_offset + 3u * query + 1u];
        const int64_t index = input[query_offset + 3u * query + 2u];
        if (left < 0 || right < left || right >= n64 || index < 0 || index >= q64 || seen[index] != 0)
            return -1;
        lefts[query] = (int32_t)left;
        rights[query] = (int32_t)right;
        indices[query] = (int32_t)index;
        seen[index] = 1;
        order[query] = query;
    }

    size_t block_size = 1u;
    while ((block_size + 1u) * (block_size + 1u) <= n) ++block_size;
    /* Stable insertion sort matches Java's stable object-array sort for ties. */
    for (size_t query = 1; query < q; ++query) {
        const size_t current = order[query];
        size_t position = query;
        while (position > 0u && query_before(current, order[position - 1u], lefts, rights, block_size)) {
            order[position] = order[position - 1u];
            --position;
        }
        order[position] = current;
    }

    int32_t results[MAX_Q];
    int32_t current_left = 0;
    int32_t current_right = -1;
    int32_t aggregate = 0;
    for (size_t sorted = 0; sorted < q; ++sorted) {
        const size_t query = order[sorted];
        const int32_t left = lefts[query];
        const int32_t right = rights[query];
        if (operation64 == 0) {
            while (current_right < right) aggregate += values[(size_t)++current_right];
            while (current_right > right) aggregate -= values[(size_t)current_right--];
            while (current_left < left) aggregate -= values[(size_t)current_left++];
            while (current_left > left) aggregate += values[(size_t)--current_left];
        } else {
            while (current_right < right) {
                if (values[(size_t)++current_right] == target) ++aggregate;
            }
            while (current_right > right) {
                if (values[(size_t)current_right] == target) --aggregate;
                --current_right;
            }
            while (current_left < left) {
                if (values[(size_t)current_left] == target) --aggregate;
                ++current_left;
            }
            while (current_left > left) {
                --current_left;
                if (values[(size_t)current_left] == target) ++aggregate;
            }
        }
        results[(size_t)indices[query]] = aggregate;
    }

    uint64_t hash = hash_byte(hash_byte(FNV_OFFSET, (uint8_t)operation64), (uint8_t)q);
    hash = hash_byte(hash, (uint8_t)(q >> 8u));
    for (size_t index = 0; index < q; ++index) {
        const uint32_t bits = (uint32_t)results[index];
        for (unsigned shift = 0; shift < 32u; shift += 8u) hash = hash_byte(hash, (uint8_t)(bits >> shift));
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
