#include <stddef.h>
#include <stdint.h>

enum { MAX_STEPS = 8, MAX_INPUT = 18, MAX_OUTPUT = 16, MAX_BID = 16 };
static void put_i64(uint8_t *out, size_t at, int64_t x) {
    uint64_t bits = (uint64_t)x;
    for (size_t b = 0; b < 8; ++b) { out[at + b] = (uint8_t)(bits & 255); bits >>= 8; }
}

int64_t single_parameter_truthful_payment(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 4 || n > MAX_INPUT || v[0] < 0 || v[0] > MAX_BID || v[1] < 1 || v[1] > MAX_STEPS) return -1;
    const size_t bid = (size_t)v[0], k = (size_t)v[1];
    if (n != 2 + 2 * k) return -1;
    for (size_t i = 0; i < k; ++i) {
        int64_t point = v[2 + 2 * i], load = v[3 + 2 * i];
        if (point < 0 || point >= MAX_BID || load < 0 || load > MAX_BID) return -1;
        if ((i == 0 && point != 0) || (i > 0 && (point <= v[2 + 2 * (i - 1)] || load > v[3 + 2 * (i - 1)]))) return -1;
    }
    int64_t allocation = 0;
    if (bid < MAX_BID) {
        for (size_t i = 0; i < k && (size_t)v[2 + 2 * i] <= bid; ++i) allocation = v[3 + 2 * i];
    }
    int64_t area = 0;
    for (size_t i = 0; i < k; ++i) {
        size_t start = (size_t)v[2 + 2 * i];
        size_t end = i + 1 < k ? (size_t)v[2 + 2 * (i + 1)] : MAX_BID;
        size_t left = start > bid ? start : bid;
        if (end > left) area += (int64_t)(end - left) * v[3 + 2 * i];
    }
    int64_t payment = (int64_t)bid * allocation + area;
    if (!out || cap < MAX_OUTPUT) return -2;
    uint8_t staged[MAX_OUTPUT];
    put_i64(staged, 0, allocation); put_i64(staged, 8, payment);
    for (size_t i = 0; i < MAX_OUTPUT; ++i) out[i] = staged[i];
    return MAX_OUTPUT;
}
