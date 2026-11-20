#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_INPUT = 203, MAX_OUTPUT = 88 };

static size_t ceil_log2(size_t value) {
    size_t exponent = 0, power = 1;
    while (power < value) { power <<= 1; ++exponent; }
    return exponent;
}

static void put64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t radio_network_bgi_broadcast(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], source64 = input[1], delta64 = input[2];
    if (n64 < 2 || n64 > MAX_N || source64 < 0 || source64 >= n64 || delta64 < 2 || delta64 > 8) return -1;
    size_t n = (size_t)n64, source = (size_t)source64, delta = (size_t)delta64;
    size_t k = 2 * ceil_log2(delta), t = ceil_log2(2 * n);
    size_t tape_at = 3 + n, tape_count = n * t * k;
    if (length != tape_at + tape_count) return -1;
    uint64_t full = (UINT64_C(1) << n) - 1U, adjacency[MAX_N] = {0};
    for (size_t v = 0; v < n; ++v) {
        int64_t raw = input[3 + v];
        if (raw < 0 || ((uint64_t)raw & ~full) != 0 || ((uint64_t)raw & (UINT64_C(1) << v)) != 0) return -1;
        adjacency[v] = (uint64_t)raw;
        size_t degree = 0;
        for (size_t u = 0; u < n; ++u) degree += (size_t)((adjacency[v] >> u) & 1U);
        if (degree > delta) return -1;
    }
    for (size_t u = 0; u < n; ++u) for (size_t v = 0; v < n; ++v)
        if (((adjacency[u] >> v) & 1U) != ((adjacency[v] >> u) & 1U)) return -1;
    for (size_t i = 0; i < tape_count; ++i) if (input[tape_at + i] != 0 && input[tape_at + i] != 1) return -1;
    size_t output_bytes = 8 * (n + 3);
    if (output == NULL || capacity < output_bytes) return -2;

    uint8_t informed[MAX_N] = {0}, active[MAX_N] = {0}, newly[MAX_N] = {0};
    size_t calls[MAX_N] = {0};
    int64_t first_slot[MAX_N];
    for (size_t v = 0; v < n; ++v) first_slot[v] = -1;
    informed[source] = 1; first_slot[source] = 0;
    int64_t transmissions = 0, phases = 0;
    for (size_t phase = 0; phase < n * t; ++phase) {
        size_t starters = 0;
        for (size_t v = 0; v < n; ++v) {
            active[v] = (uint8_t)(informed[v] && calls[v] < t);
            newly[v] = 0;
            starters += active[v] != 0;
        }
        if (starters == 0) break;
        for (size_t slot = 0; slot < k; ++slot) {
            for (size_t sender = 0; sender < n; ++sender) if (active[sender]) ++transmissions;
            for (size_t receiver = 0; receiver < n; ++receiver) {
                if (informed[receiver] || newly[receiver]) continue;
                size_t senders = 0;
                for (size_t sender = 0; sender < n; ++sender)
                    if (active[sender] && ((adjacency[sender] >> receiver) & 1U)) ++senders;
                if (senders == 1) { newly[receiver] = 1; first_slot[receiver] = (int64_t)(phase * k + slot); }
            }
            for (size_t sender = 0; sender < n; ++sender) if (active[sender]) {
                size_t at = tape_at + (sender * t + calls[sender]) * k + slot;
                if (slot + 1 == k || input[at] == 0) active[sender] = 0;
            }
        }
        for (size_t v = 0; v < n; ++v) {
            if (informed[v] && calls[v] < t) ++calls[v];
            if (newly[v]) informed[v] = 1;
        }
        phases = (int64_t)phase + 1;
    }
    uint8_t staged[MAX_OUTPUT] = {0};
    put64(staged, 0, n64); put64(staged, 8, phases); put64(staged, 16, transmissions);
    for (size_t v = 0; v < n; ++v) put64(staged, 24 + 8 * v, first_slot[v]);
    for (size_t i = 0; i < output_bytes; ++i) output[i] = staged[i];
    return (int64_t)output_bytes;
}
