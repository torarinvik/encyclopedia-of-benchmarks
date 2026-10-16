#include <cstddef>
#include <cstdint>

extern "C" std::int64_t select_bits(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > 3) {
        return -1;
    }

    const std::int64_t number = values[0];
    if (number < 0 || number > INT64_C(9007199254740991)) {
        return -1;
    }

    const std::int64_t first = length >= 2 ? values[1] : 1;
    const std::int64_t last = length >= 3 ? values[2] : 53;
    if (first < 1 || first > 53 || last < 1 || last > 53) {
        return -1;
    }

    const std::uint64_t modulus = UINT64_C(1) << static_cast<unsigned>(last);
    return static_cast<std::int64_t>(
        (static_cast<std::uint64_t>(number) % modulus) >> static_cast<unsigned>(first - 1));
}
