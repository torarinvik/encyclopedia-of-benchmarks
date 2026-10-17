#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t simplest_radical_form(const std::int64_t *values, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length != 1) return -1;
    const std::int64_t original = values[0];
    if (original < 0 || original > 100000000) return -1;
    if (output == nullptr || capacity < 16) return -2;

    std::int64_t coefficient = 1, root_term = 1;
    if (original == 0) {
        root_term = 0;
    } else {
        std::int64_t remainder = original;
        for (std::int64_t factor = 2; factor * factor <= original; ++factor) {
            std::int64_t count = 0;
            while (remainder % factor == 0) { remainder /= factor; ++count; }
            for (std::int64_t power = 0; power < count / 2; ++power) coefficient *= factor;
            if (count % 2 != 0) root_term *= factor;
        }
        root_term *= remainder;
    }
    put_i64(output, 0, coefficient);
    put_i64(output, 8, root_term);
    return 16;
}
