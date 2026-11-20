#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaximumLength = 10;

std::int64_t choose(int total, int selected) {
    if (total < 0 || selected < 0 || selected > total) return 0;
    if (selected > total - selected) selected = total - selected;
    std::int64_t value = 1;
    for (int factor = 1; factor <= selected; ++factor)
        value = value * (total - selected + factor) / factor;
    return value;
}

std::int64_t multinomial3(int total, int first, int second) {
    if (total < 0 || first < 0 || second < 0 || first > total || second > total ||
        first + second > total) return 0;
    return choose(total, first) * choose(total - first, second);
}

std::int64_t gcd(std::int64_t left, std::int64_t right) {
    while (right != 0) {
        const std::int64_t remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

void write_word(std::uint8_t* output, std::size_t word, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}  // namespace

extern "C" std::int64_t spatial_motif_different_type_contact_pmf(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) {
    if (input == nullptr || length != 5) return -1;
    const auto length_input = input[0];
    const auto x1_input = input[1];
    const auto y1_input = input[2];
    const auto x2_input = input[3];
    const auto y2_input = input[4];
    if (length_input < 1 || length_input > kMaximumLength || x1_input < 0 ||
        y1_input < 0 || x2_input < 0 || y2_input < 0 || x1_input > length_input ||
        y1_input > length_input || x2_input > length_input || y2_input > length_input)
        return -1;
    if (x1_input + y1_input > length_input || x2_input + y2_input > length_input)
        return -1;

    const int n = static_cast<int>(length_input);
    const int x1 = static_cast<int>(x1_input), y1 = static_cast<int>(y1_input);
    const int x2 = static_cast<int>(x2_input), y2 = static_cast<int>(y2_input);
    const auto denominator = multinomial3(n, x2, y2);
    std::array<std::int64_t, kMaximumLength + 1> counts{};

    for (int contacts = 0; contacts <= n; ++contacts) {
        for (int xx = 0; xx <= x1; ++xx) {
            for (int xy = 0; xy <= x1 - xx; ++xy) {
                const int yx = contacts - xy;
                if (yx < 0 || yx > y1) continue;
                for (int yy = 0; yy <= y1 - yx; ++yy) {
                    counts[contacts] += multinomial3(x1, xx, xy)
                                     * multinomial3(y1, yx, yy)
                                     * multinomial3(n - x1 - y1,
                                                   x2 - xx - yx,
                                                   y2 - xy - yy);
                }
            }
        }
    }

    std::int64_t mean_numerator = 0;
    for (int contacts = 0; contacts <= n; ++contacts)
        mean_numerator += static_cast<std::int64_t>(contacts) * counts[contacts];
    std::int64_t mean_denominator = denominator;
    const auto divisor = gcd(mean_numerator, mean_denominator);
    mean_numerator /= divisor;
    mean_denominator /= divisor;

    const std::size_t word_count = static_cast<std::size_t>(n) + 5;
    const std::size_t bytes = word_count * 8;
    if (output == nullptr || capacity < bytes) return -2;
    write_word(output, 0, n);
    write_word(output, 1, denominator);
    for (int contacts = 0; contacts <= n; ++contacts)
        write_word(output, 2 + static_cast<std::size_t>(contacts), counts[contacts]);
    write_word(output, static_cast<std::size_t>(n) + 3, mean_numerator);
    write_word(output, static_cast<std::size_t>(n) + 4, mean_denominator);
    return static_cast<std::int64_t>(bytes);
}
