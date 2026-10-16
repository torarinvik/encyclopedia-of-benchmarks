#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
void put_u64(std::uint8_t *out, std::size_t offset, std::uint64_t bits) {
    for (std::size_t b = 0; b < 8; ++b) out[offset + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) { put_u64(out, offset, static_cast<std::uint64_t>(value)); }
void put_f64(std::uint8_t *out, std::size_t offset, double value) {
    std::uint64_t bits;
    std::memcpy(&bits, &value, sizeof(bits));
    put_u64(out, offset, bits);
}
}

extern "C" std::int64_t similarity_search(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 3 || length > 643) return -1;
    const auto rv = input[0], qv = input[1], fv = input[2];
    if (rv < 1 || rv > 32 || qv < 1 || qv > 8 || fv < 1 || fv > 16) return -1;
    const auto rows = static_cast<std::size_t>(rv), queries = static_cast<std::size_t>(qv), features = static_cast<std::size_t>(fv);
    if (length != 3 + (rows + queries) * features) return -1;
    for (std::size_t i = 0; i < (rows + queries) * features; ++i)
        if (input[3 + i] < -1000000 || input[3 + i] > 1000000) return -1;
    const auto record = 16 + 8 * features, needed = queries * record;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t query = 0; query < queries; ++query) {
        std::size_t best = 0;
        double sum = 0.0;
        for (std::size_t f = 0; f < features; ++f) {
            const double delta = static_cast<double>(input[3 + f]) / 1000000.0 -
                static_cast<double>(input[3 + rows * features + query * features + f]) / 1000000.0;
            sum += delta * delta;
        }
        double best_distance = std::sqrt(sum);
        for (std::size_t row = 1; row < rows; ++row) {
            sum = 0.0;
            for (std::size_t f = 0; f < features; ++f) {
                const double delta = static_cast<double>(input[3 + row * features + f]) / 1000000.0 -
                    static_cast<double>(input[3 + rows * features + query * features + f]) / 1000000.0;
                sum += delta * delta;
            }
            const double distance = std::sqrt(sum);
            if (distance < best_distance) { best = row; best_distance = distance; }
        }
        const auto base = query * record;
        put_i64(output, base, static_cast<std::int64_t>(best));
        put_f64(output, base + 8, best_distance);
        for (std::size_t f = 0; f < features; ++f) put_i64(output, base + 16 + 8 * f, input[3 + best * features + f]);
    }
    return static_cast<std::int64_t>(needed);
}
