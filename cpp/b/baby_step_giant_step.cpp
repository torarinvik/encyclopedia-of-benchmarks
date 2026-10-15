// Bounded baby-step giant-step discrete logarithm.
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace {
constexpr std::size_t table_size = 65536;
constexpr std::size_t table_mask = table_size - 1;
constexpr std::uint64_t max_modulus = 1'000'000'007;

std::uint64_t ceil_sqrt(std::uint64_t value)
{
    std::uint64_t low = 1, high = 31624;
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

void insert_baby(std::vector<std::uint64_t>& keys, std::vector<std::uint32_t>& encoded_steps,
                 std::uint64_t key, std::uint32_t step)
{
    auto slot = static_cast<std::size_t>(key & table_mask);
    while (encoded_steps[slot] != 0 && keys[slot] != key) slot = (slot + 1) & table_mask;
    keys[slot] = key;
    encoded_steps[slot] = step + 1;
}

std::int64_t find_baby(const std::vector<std::uint64_t>& keys,
                       const std::vector<std::uint32_t>& encoded_steps, std::uint64_t key)
{
    auto slot = static_cast<std::size_t>(key & table_mask);
    while (encoded_steps[slot] != 0) {
        if (keys[slot] == key) return static_cast<std::int64_t>(encoded_steps[slot] - 1);
        slot = (slot + 1) & table_mask;
    }
    return -1;
}
} // namespace

extern "C" std::int64_t baby_step_giant_step(const std::int64_t *values, std::size_t length)
{
    if (length != 3 || values == nullptr) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        static_cast<std::uint64_t>(values[2]) > max_modulus ||
        values[0] >= values[2] || values[1] >= values[2]) return -1;
    const auto a = static_cast<std::uint64_t>(values[0]);
    const auto b = static_cast<std::uint64_t>(values[1]);
    const auto modulus = static_cast<std::uint64_t>(values[2]);
    if (std::gcd(a, modulus) != 1) return -1;

    const auto m = ceil_sqrt(modulus);
    std::vector<std::uint64_t> keys(table_size, 0);
    std::vector<std::uint32_t> encoded_steps(table_size, 0);
    std::uint64_t step = 1;
    for (std::uint64_t index = 0; index < m; ++index) {
        insert_baby(keys, encoded_steps, (step * b) % modulus, static_cast<std::uint32_t>(index));
        step = (step * a) % modulus;
    }
    const auto giant_step = step;
    for (std::uint64_t index = m; index <= modulus; index += m) {
        const auto baby_index = find_baby(keys, encoded_steps, step);
        if (baby_index >= 0) return static_cast<std::int64_t>(index) - baby_index;
        step = (step * giant_step) % modulus;
    }
    return -1;
}
