#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_K = 8, MAX_INPUT = 75 };

static void put64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t radio_network_decay_phase(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], k64 = input[1], initial = input[2];
    if (n64 < 2 || n64 > MAX_N || k64 < 1 || k64 > MAX_K || length != 3 + (size_t)n64 + (size_t)n64 * (size_t)k64) return -1;
    size_t n = (size_t)n64, k = (size_t)k64;
    uint64_t full = (UINT64_C(1) << n) - 1U;
    if (initial <= 0 || ((uint64_t)initial & ~full) != 0) return -1;
    uint64_t adjacency[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) {
        int64_t raw = input[3 + v];
        if (raw < 0 || ((uint64_t)raw & ~full) != 0 || ((uint64_t)raw & (UINT64_C(1) << v)) != 0) return -1;
        adjacency[v] = (uint64_t)raw;
    }
    for (size_t u = 0; u < n; ++u) for (size_t v = 0; v < n; ++v)
        if (((adjacency[u] >> v) & 1U) != ((adjacency[v] >> u) & 1U)) return -1;
    size_t tape_at = 3 + n;
    for (size_t i = 0; i < n * k; ++i) if (input[tape_at + i] != 0 && input[tape_at + i] != 1) return -1;
    if (output == NULL || capacity < 16) return -2;
    uint8_t staged[16];
    uint8_t active[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) active[v] = (uint8_t)(((uint64_t)initial >> v) & 1U);
    uint64_t newly = 0;
    int64_t transmissions = 0;
    for (size_t slot = 0; slot < k; ++slot) {
        for (size_t v = 0; v < n; ++v) if (active[v]) ++transmissions;
        for (size_t receiver = 0; receiver < n; ++receiver) {
            if (((uint64_t)initial >> receiver) & 1U) continue;
            size_t count = 0;
            for (size_t sender = 0; sender < n; ++sender)
                if (active[sender] && ((adjacency[sender] >> receiver) & 1U)) ++count;
            if (count == 1) newly |= UINT64_C(1) << receiver;
        }
        for (size_t sender = 0; sender < n; ++sender) if (active[sender])
            if (input[tape_at + sender * k + slot] == 0 || slot + 1 == k) active[sender] = 0;
    }
    put64(staged, 0, (int64_t)newly); put64(staged, 8, transmissions);
    for (size_t i = 0; i < sizeof(staged); ++i) output[i] = staged[i];
    return 16;
}
