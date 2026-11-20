#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxVertices = 16;
constexpr std::size_t kMaxParseableLength = 34;
constexpr std::int64_t kScale = 1'000'000;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 0xffU);
        bits >>= 8;
    }
}

std::int64_t rounded_micro(std::int64_t numerator, std::int64_t denominator) noexcept {
    if (denominator < 0) { numerator = -numerator; denominator = -denominator; }
    const std::int64_t sign = numerator < 0 ? -1 : 1;
    const auto magnitude = static_cast<std::uint64_t>(numerator < 0 ? -numerator : numerator);
    const auto scaled = magnitude * static_cast<std::uint64_t>(kScale);
    const auto divisor = static_cast<std::uint64_t>(denominator);
    auto quotient = scaled / divisor;
    if (2 * (scaled % divisor) >= divisor) ++quotient;
    return sign * static_cast<std::int64_t>(quotient);
}
}

extern "C" std::int64_t polygon_area_centroid(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 7 || length > kMaxParseableLength) return -1;
    const std::int64_t count_value = input[0];
    if (count_value < 3 || count_value > static_cast<std::int64_t>(kMaxVertices)) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != 1 + 2 * count) return -1;

    std::int64_t xs[kMaxVertices]{};
    std::int64_t ys[kMaxVertices]{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto x = input[1 + 2 * i];
        const auto y = input[2 + 2 * i];
        if (x < -50 || x > 50 || y < -50 || y > 50) return -1;
        for (std::size_t j = 0; j < i; ++j)
            if (xs[j] == x && ys[j] == y) return -1;
        xs[i] = x;
        ys[i] = y;
    }

    std::int64_t twice_area = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto next = (i + 1) % count;
        twice_area += xs[i] * ys[next] - xs[next] * ys[i];
    }
    if (twice_area == 0) return -1;
    const std::int64_t orientation = twice_area > 0 ? 1 : -1;
    for (std::size_t i = 0; i < count; ++i) {
        const auto next = (i + 1) % count;
        for (std::size_t j = 0; j < count; ++j) {
            if (j == i || j == next) continue;
            const auto side = (xs[next] - xs[i]) * (ys[j] - ys[i]) -
                              (ys[next] - ys[i]) * (xs[j] - xs[i]);
            if (side * orientation <= 0) return -1;
        }
    }

    std::int64_t numerator_x = 0;
    std::int64_t numerator_y = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto next = (i + 1) % count;
        const auto cross = xs[i] * ys[next] - xs[next] * ys[i];
        numerator_x += (xs[i] + xs[next]) * cross;
        numerator_y += (ys[i] + ys[next]) * cross;
    }
    const auto x_micro = rounded_micro(numerator_x, 3 * twice_area);
    const auto y_micro = rounded_micro(numerator_y, 3 * twice_area);
    if (output == nullptr || capacity < 16) return -2;
    store_i64_le(output, 0, x_micro);
    store_i64_le(output, 8, y_micro);
    return 16;
}
