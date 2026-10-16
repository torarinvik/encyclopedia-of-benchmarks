#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_u64(uint8_t *out, size_t offset, uint64_t bits) {
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}
static void put_i64(uint8_t *out, size_t offset, int64_t value) { put_u64(out, offset, (uint64_t)value); }
static void put_f64(uint8_t *out, size_t offset, double value) {
    uint64_t bits;
    memcpy(&bits, &value, sizeof(bits));
    put_u64(out, offset, bits);
}

int64_t similarity_search(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 3 || length > 643) return -1;
    const int64_t rv = input[0], qv = input[1], fv = input[2];
    if (rv < 1 || rv > 32 || qv < 1 || qv > 8 || fv < 1 || fv > 16) return -1;
    const size_t rows = (size_t)rv, queries = (size_t)qv, features = (size_t)fv;
    if (length != 3 + (rows + queries) * features) return -1;
    for (size_t i = 0; i < (rows + queries) * features; ++i)
        if (input[3 + i] < -1000000 || input[3 + i] > 1000000) return -1;
    const size_t record = 16 + 8 * features, needed = queries * record;
    if (output == NULL || output_capacity < needed) return -2;

    for (size_t query = 0; query < queries; ++query) {
        size_t best = 0;
        double best_sum = 0.0;
        for (size_t f = 0; f < features; ++f) {
            const double delta = (double)input[3 + f] / 1000000.0 -
                (double)input[3 + rows * features + query * features + f] / 1000000.0;
            best_sum += delta * delta;
        }
        double best_distance = sqrt(best_sum);
        for (size_t row = 1; row < rows; ++row) {
            double sum = 0.0;
            for (size_t f = 0; f < features; ++f) {
                const double delta = (double)input[3 + row * features + f] / 1000000.0 -
                    (double)input[3 + rows * features + query * features + f] / 1000000.0;
                sum += delta * delta;
            }
            const double distance = sqrt(sum);
            if (distance < best_distance) { best = row; best_distance = distance; }
        }
        const size_t base = query * record;
        put_i64(output, base, (int64_t)best);
        put_f64(output, base + 8, best_distance);
        for (size_t f = 0; f < features; ++f)
            put_i64(output, base + 16 + 8 * f, input[3 + best * features + f]);
    }
    return (int64_t)needed;
}
