#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_limit = 61;
constexpr std::size_t max_parseable_length = 2;
constexpr std::size_t max_triples = 69;

bool is_prime(std::int64_t value) noexcept {
    if (value < 2) return false;
    if (value % 2 == 0) return value == 2;
    for (std::int64_t divisor = 3; divisor <= value / divisor; divisor += 2) {
        if (value % divisor == 0) return false;
    }
    return true;
}

std::int64_t mod_nonnegative(std::int64_t value, std::int64_t modulus) noexcept {
    const auto result = value % modulus;
    return result < 0 ? result + modulus : result;
}

void put_u32_le(std::uint8_t *output, std::size_t offset, std::uint32_t value) noexcept {
    for (std::size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
}
}

extern "C" std::int64_t three_prime_carmichael_enumerator(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length || length != 1) return -1;
    const std::int64_t limit = input[0];
    if (limit < 2 || limit > max_limit) return -1;

    std::uint32_t triples[max_triples][3];
    std::size_t count = 0;
    for (std::int64_t p1 = 2; p1 <= limit; ++p1) {
        if (!is_prime(p1)) continue;
        for (std::int64_t h3 = 2; h3 < p1; ++h3) {
            const std::int64_t g = h3 + p1;
            for (std::int64_t d = 1; d < g; ++d) {
                if ((g * (p1 - 1)) % d != 0) continue;
                if (mod_nonnegative(-p1 * p1, h3) != d % h3) continue;
                const std::int64_t p2 = 1 + (p1 - 1) * g / d;
                if (p2 <= p1 || !is_prime(p2)) continue;
                const std::int64_t p3 = 1 + (p1 * p2) / h3;
                if (p3 <= p2 || !is_prime(p3)) continue;
                if ((p2 * p3) % (p1 - 1) != 1) continue;
                if (count >= max_triples) return -1;
                triples[count][0] = static_cast<std::uint32_t>(p1);
                triples[count][1] = static_cast<std::uint32_t>(p2);
                triples[count][2] = static_cast<std::uint32_t>(p3);
                ++count;
            }
        }
    }

    const std::size_t required = 4 + 12 * count;
    if (output == nullptr || capacity < required) return -2;
    put_u32_le(output, 0, static_cast<std::uint32_t>(count));
    for (std::size_t i = 0; i < count; ++i) {
        for (std::size_t field = 0; field < 3; ++field)
            put_u32_le(output, 4 + 12 * i + 4 * field, triples[i][field]);
    }
    return static_cast<std::int64_t>(required);
}
