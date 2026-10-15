/* Two-stack sliding window with aggregate GCD, preserving the earliest shortest window. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 128;

std::int64_t gcd_positive(std::int64_t a, std::int64_t b) noexcept
{
    while (b != 0) { const auto remainder = a % b; a = b; b = remainder; }
    return a;
}

void push(std::int64_t value, std::int64_t *items, std::int64_t *aggregates, std::size_t &length) noexcept
{
    items[length] = value;
    aggregates[length] = length == 0 ? value : gcd_positive(aggregates[length - 1], value);
    ++length;
}
}

extern "C" std::int64_t shortest_coprime_segment(const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length > max_length || (length != 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i) if (input[i] < 1 || input[i] > 1000) return -1;
    std::int64_t front[max_length], front_gcd[max_length], back[max_length], back_gcd[max_length];
    std::size_t front_length = 0, back_length = 0;
    std::size_t left = 0, best_start = 0, best_length = length + 1;
    for (std::size_t right = 0; right < length; ++right) {
        push(input[right], back, back_gcd, back_length);
        auto window_gcd = gcd_positive(front_length ? front_gcd[front_length - 1] : 0,
                                       back_length ? back_gcd[back_length - 1] : 0);
        while (window_gcd == 1) {
            const auto current_length = right - left + 1;
            if (current_length < best_length) { best_length = current_length; best_start = left; }
            if (front_length == 0) {
                while (back_length > 0) {
                    const auto value = back[--back_length];
                    push(value, front, front_gcd, front_length);
                }
            }
            --front_length;
            ++left;
            window_gcd = gcd_positive(front_length ? front_gcd[front_length - 1] : 0,
                                      back_length ? back_gcd[back_length - 1] : 0);
        }
    }
    if (best_length > length) return 0;
    const auto byte_count = best_length * sizeof(std::int64_t);
    if (output == nullptr || output_capacity < byte_count) return -2;
    for (std::size_t i = 0; i < best_length; ++i) {
        const auto bits = static_cast<std::uint64_t>(input[best_start + i]);
        for (std::size_t byte = 0; byte < 8; ++byte) output[8 * i + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
    }
    return static_cast<std::int64_t>(byte_count);
}
