#include <cstddef>
#include <cstdint>

namespace {
constexpr std::uint64_t scale = 1000000;
bool put_byte(std::uint8_t *out, std::size_t cap, std::size_t &len, std::uint8_t value) {
    if (len >= cap) return false;
    out[len++] = value;
    return true;
}
bool put_text(std::uint8_t *out, std::size_t cap, std::size_t &len, const char *s) {
    while (*s) if (!put_byte(out, cap, len, static_cast<std::uint8_t>(*s++))) return false;
    return true;
}
bool put_uint(std::uint8_t *out, std::size_t cap, std::size_t &len, std::uint64_t value) {
    std::uint8_t digits[20]; std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>('0' + value % 10); value /= 10; } while (value);
    while (count) if (!put_byte(out, cap, len, digits[--count])) return false;
    return true;
}
bool put_fixed(std::uint8_t *out, std::size_t cap, std::size_t &len, std::uint64_t ticks) {
    const auto whole = ticks / scale; auto fraction = ticks % scale;
    if (!put_uint(out, cap, len, whole) || !put_byte(out, cap, len, '.')) return false;
    for (std::uint64_t divisor = 100000; divisor; divisor /= 10)
        if (!put_byte(out, cap, len, static_cast<std::uint8_t>('0' + fraction / divisor % 10))) return false;
    return true;
}
}

extern "C" std::int64_t cantor_set(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t capacity) noexcept {
    if (!input || length != 3 || input[0] < 0 || input[0] > input[1] || input[1] > 100000 || input[2] < 0 || input[2] > 6) return -1;
    if (!output) return -2;
    std::uint64_t positions[64] = {}, next[64] = {}, denominator = 1;
    const auto start = static_cast<std::uint64_t>(input[0]), span = static_cast<std::uint64_t>(input[1] - input[0]);
    std::size_t count = 1, len = 0;
    for (std::int64_t level = 0; level <= input[2]; ++level) {
        if (!put_text(output, capacity, len, "Level ") || !put_uint(output, capacity, len, level) || !put_byte(output, capacity, len, '\t')) return -2;
        for (std::size_t i = 0; i < count; ++i) {
            const auto left_num = start * denominator + span * positions[i];
            const auto right_num = start * denominator + span * (positions[i] + 1);
            const auto left = (left_num * scale + denominator / 2) / denominator;
            const auto right = (right_num * scale + denominator / 2) / denominator;
            if (!put_text(output, capacity, len, "\t[") || !put_fixed(output, capacity, len, left) || !put_text(output, capacity, len, "] -- [") || !put_fixed(output, capacity, len, right) || !put_byte(output, capacity, len, ']')) return -2;
        }
        if (!put_byte(output, capacity, len, '\n')) return -2;
        if (level < input[2]) {
            if (!put_byte(output, capacity, len, '\n')) return -2;
            for (std::size_t i = 0; i < count; ++i) { next[2 * i] = positions[i] * 3; next[2 * i + 1] = positions[i] * 3 + 2; }
            count *= 2; for (std::size_t i = 0; i < count; ++i) positions[i] = next[i]; denominator *= 3;
        }
    }
    if (len >= capacity) return -2;
    output[len++] = 0;
    return static_cast<std::int64_t>(len);
}
