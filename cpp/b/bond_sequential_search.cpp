#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 64;
constexpr std::int64_t MAX_VALUE = 255;
constexpr std::int64_t ABSENT_CODE = 64;
constexpr std::int64_t PACK_BASE = 65;
}

extern "C" std::int64_t bond_sequential_search(const std::int64_t *input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > 68) return -1;
    const auto count_value = input[0];
    const auto key_a = input[1];
    const auto key_b = input[2];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(MAX_N)
            || length != static_cast<std::size_t>(count_value) + 3
            || key_a < 0 || key_a > MAX_VALUE || key_b < 0 || key_b > MAX_VALUE
            || key_a == key_b) return -1;

    const auto count = static_cast<std::size_t>(count_value);
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = input[i + 3];
        if (value < 0 || value > MAX_VALUE) return -1;
    }

    auto index_a = ABSENT_CODE;
    auto index_b = ABSENT_CODE;
    const auto composite = key_a | key_b;
    for (std::size_t i = 0; i < count && (index_a == ABSENT_CODE || index_b == ABSENT_CODE); ++i) {
        const auto value = input[i + 3];
        if ((value & composite) != value) continue;
        if (index_a == ABSENT_CODE && value == key_a) index_a = static_cast<std::int64_t>(i);
        if (index_b == ABSENT_CODE && value == key_b) index_b = static_cast<std::int64_t>(i);
    }
    return index_a * PACK_BASE + index_b;
}
