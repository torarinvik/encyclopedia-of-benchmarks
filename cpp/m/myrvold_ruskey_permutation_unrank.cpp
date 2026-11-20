#include <cstddef>
#include <cstdint>

extern "C" std::int64_t myrvold_ruskey_permutation_unrank(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 3) return -1;
    if (length != 2) return -1;

    const std::int64_t n_value = input[0];
    const std::int64_t rank_value = input[1];
    if (n_value < 0 || n_value > 8 || rank_value < 0) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    std::int64_t factorial = 1;
    for (std::size_t factor = 2; factor <= n; ++factor)
        factorial *= static_cast<std::int64_t>(factor);
    if (rank_value >= factorial) return -1;

    const std::size_t required = 8 * n;
    if (output == nullptr || capacity < required) return -2;

    std::int64_t permutation[8]{};
    for (std::size_t i = 0; i < n; ++i) permutation[i] = static_cast<std::int64_t>(i);
    auto remainder = rank_value;
    for (std::size_t size = n; size > 0; --size) {
        const auto choice = static_cast<std::size_t>(remainder % static_cast<std::int64_t>(size));
        remainder /= static_cast<std::int64_t>(size);
        const std::size_t last = size - 1;
        const auto held = permutation[last];
        permutation[last] = permutation[choice];
        permutation[choice] = held;
    }

    for (std::size_t i = 0; i < n; ++i) {
        const auto value = static_cast<std::uint64_t>(permutation[i]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[8 * i + byte] = static_cast<std::uint8_t>(value >> (8 * byte));
    }
    return static_cast<std::int64_t>(required);
}
