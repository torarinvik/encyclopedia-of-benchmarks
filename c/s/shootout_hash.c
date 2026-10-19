#include <stdint.h>
#include <stdlib.h>

#define SHOOTOUT_HASH_MAX_N INT64_C(3500000)

static const uint32_t bucket_primes[] = {
    53U, 97U, 193U, 389U, 769U, 1543U, 3079U, 6151U, 12289U, 24593U,
    49157U, 98317U, 196613U, 393241U, 786433U, 1572869U, 3145739U,
    6291469U, 12582917U, 25165843U, 50331653U, 100663319U, 201326611U,
    402653189U, 805306457U, 1610612741U, 3221225473U, 4294967291U
};

static size_t bucket_count_for(uint32_t n) {
    size_t index = 0;
    while (bucket_primes[index] < n) ++index;
    return bucket_primes[index];
}

static size_t hash_key(uint32_t value, uint32_t base, size_t bucket_count) {
    uint8_t reverse[16];
    size_t length = 0;
    do {
        uint32_t digit = value % base;
        reverse[length++] = (uint8_t)(digit < 10 ? '0' + digit : 'a' + digit - 10);
        value /= base;
    } while (value != 0);
    uint64_t hash = 0;
    while (length != 0) hash = 5 * hash + reverse[--length];
    return (size_t)(hash % bucket_count);
}

static int hex_key_matches_decimal(uint32_t hex_value, uint32_t decimal_value) {
    while (hex_value != 0 && decimal_value != 0) {
        uint32_t digit = hex_value & 15U;
        if (digit >= 10U || digit != decimal_value % 10U) return 0;
        hex_value >>= 4;
        decimal_value /= 10U;
    }
    return hex_value == 0 && decimal_value == 0;
}

int64_t shootout_hash(int64_t n) {
    if (n < 0 || n > SHOOTOUT_HASH_MAX_N) return -1;
    const uint32_t bound = (uint32_t)n;
    const size_t bucket_count = bucket_count_for(bound);
    uint32_t *heads = (uint32_t *)calloc(bucket_count, sizeof(uint32_t));
    uint32_t *next = (uint32_t *)calloc((size_t)bound + 1, sizeof(uint32_t));
    if (heads == NULL || next == NULL) {
        free(heads);
        free(next);
        return -1;
    }

    for (uint32_t value = 1; value <= bound; ++value) {
        size_t bucket = hash_key(value, 16U, bucket_count);
        uint32_t node = heads[bucket];
        uint32_t previous = 0;
        while (node != 0) {
            if (node == value) break;
            previous = node;
            node = next[node];
        }
        if (node == 0) {
            if (previous == 0) heads[bucket] = value;
            else next[previous] = value;
        }
    }

    int64_t found = 0;
    for (uint32_t value = bound; value > 0; --value) {
        size_t bucket = hash_key(value, 10U, bucket_count);
        uint32_t node = heads[bucket];
        while (node != 0) {
            if (hex_key_matches_decimal(node, value)) {
                ++found;
                break;
            }
            node = next[node];
        }
    }

    free(heads);
    free(next);
    return found;
}
