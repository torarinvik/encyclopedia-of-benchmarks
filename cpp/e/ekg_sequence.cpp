#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 8;
constexpr std::size_t max_candidate = 40320;
constexpr std::size_t max_parseable_length = 2;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

void store_i64_le(std::uint8_t* output, std::size_t offset,
                  std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t ekg_sequence(const std::int64_t* input,
                                      std::size_t length,
                                      std::uint8_t* output,
                                      std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const std::int64_t requested = input[0];
    if (length != 1 || requested < 1 || requested > static_cast<std::int64_t>(max_n))
        return -1;

    std::int64_t terms[max_n]{};
    std::uint8_t used[max_candidate + 1]{};
    terms[0] = 1;
    used[1] = 1;
    std::size_t term_count = 1;
    if (requested >= 2) {
        terms[1] = 2;
        used[2] = 1;
        term_count = 2;
    }

    while (term_count < static_cast<std::size_t>(requested)) {
        const auto position = static_cast<std::int64_t>(term_count + 1);
        const auto previous = terms[term_count - 1];
        const auto search_bound = previous * position;
        std::int64_t candidate = 1;
        while (candidate <= search_bound) {
            if (used[static_cast<std::size_t>(candidate)] == 0
                && gcd_i64(previous, candidate) > 1) break;
            ++candidate;
        }
        if (candidate > search_bound) return -1;
        terms[term_count++] = candidate;
        used[static_cast<std::size_t>(candidate)] = 1;
    }

    const auto output_bytes = static_cast<std::size_t>(requested) * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < term_count; ++index)
        store_i64_le(output, index * 8, terms[index]);
    return static_cast<std::int64_t>(output_bytes);
}
