#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_points = 32;
constexpr std::size_t max_words = 34;
constexpr std::size_t max_output = 320;

std::int64_t adapt_bias(std::int64_t delta, std::int64_t point_count, bool first_time) {
    delta /= first_time ? 700 : 2;
    delta += delta / point_count;
    std::int64_t k = 0;
    while (delta > ((36 - 1) * 26) / 2) {
        delta /= 35;
        k += 36;
    }
    return k + (36 * delta) / (delta + 38);
}

std::uint8_t encode_digit(std::int64_t digit) {
    return static_cast<std::uint8_t>(digit < 26 ? 'a' + digit : '0' + digit - 26);
}

bool scalar(std::int64_t value) {
    return value >= 0 && value <= 0x10ffff && !(value >= 0xd800 && value <= 0xdfff);
}

std::size_t encode(const std::int64_t* points, std::size_t count,
                   std::array<std::uint8_t, max_output>& output) {
    std::size_t basic_count = 0;
    for (std::size_t i = 0; i < count; ++i) {
        if (points[i] < 0x80) output[basic_count++] = static_cast<std::uint8_t>(points[i]);
    }
    std::size_t written = basic_count;
    if (basic_count != 0) output[written++] = '-';
    std::int64_t n = 128, delta = 0, bias = 72;
    std::size_t handled = basic_count;
    while (handled < count) {
        std::int64_t minimum = 0x110000;
        for (std::size_t i = 0; i < count; ++i)
            if (points[i] >= n && points[i] < minimum) minimum = points[i];
        delta += (minimum - n) * static_cast<std::int64_t>(handled + 1);
        n = minimum;
        for (std::size_t i = 0; i < count; ++i) {
            if (points[i] < n) ++delta;
            if (points[i] == n) {
                auto q = delta;
                for (std::int64_t k = 36;; k += 36) {
                    const auto threshold = k <= bias ? 1 : (k >= bias + 26 ? 26 : k - bias);
                    if (q < threshold) {
                        output[written++] = encode_digit(q);
                        break;
                    }
                    output[written++] = encode_digit(threshold + (q - threshold) % (36 - threshold));
                    q = (q - threshold) / (36 - threshold);
                }
                bias = adapt_bias(delta, static_cast<std::int64_t>(handled + 1), handled == basic_count);
                delta = 0;
                ++handled;
            }
        }
        ++delta;
        ++n;
    }
    return written;
}
}

extern "C" std::int64_t punycode_codepoint_sequence_encode(
    const std::int64_t* input, std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 1 || length > max_words) return -1;
    const auto count_word = input[0];
    if (count_word < 0 || count_word > static_cast<std::int64_t>(max_points) ||
        length != static_cast<std::size_t>(count_word) + 1) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(count_word); ++i)
        if (!scalar(input[i + 1])) return -1;
    std::array<std::uint8_t, max_output> staged{};
    const auto written = encode(input + 1, static_cast<std::size_t>(count_word), staged);
    if (written > max_output) return -1;
    if (written != 0 && (output == nullptr || capacity < written)) return -2;
    for (std::size_t i = 0; i < written; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(written);
}
