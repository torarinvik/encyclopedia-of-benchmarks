// Extended baby-step giant-step for a bounded modular discrete logarithm.
#include <cstddef>
#include <cstdint>
#include <numeric>
#include <vector>

namespace {
constexpr std::size_t table_size = 65536;
constexpr std::size_t table_mask = table_size - 1;
constexpr std::uint64_t max_modulus = 1'000'000'000;

std::uint64_t ceil_sqrt(std::uint64_t value)
{
    std::uint64_t low = 1, high = 31623;
    while (low < high) {
        const auto middle = low + (high - low) / 2;
        if (middle * middle >= value) high = middle;
        else low = middle + 1;
    }
    return low;
}

std::uint64_t pow_mod(std::uint64_t base, std::uint64_t exponent, std::uint64_t modulus)
{
    std::uint64_t result = 1 % modulus;
    while (exponent != 0) {
        if ((exponent & 1) != 0) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}

std::int64_t inverse_mod(std::uint64_t value, std::uint64_t modulus)
{
    std::int64_t old_r = static_cast<std::int64_t>(value), r = static_cast<std::int64_t>(modulus);
    std::int64_t old_t = 1, t = 0;
    while (r != 0) {
        const auto quotient = old_r / r;
        const auto next_r = old_r - quotient * r;
        const auto next_t = old_t - quotient * t;
        old_r = r; r = next_r; old_t = t; t = next_t;
    }
    if (old_r != 1) return -1;
    old_t %= static_cast<std::int64_t>(modulus);
    if (old_t < 0) old_t += static_cast<std::int64_t>(modulus);
    return old_t;
}

void insert_baby(std::vector<std::uint64_t>& keys, std::vector<std::uint32_t>& steps,
                 std::uint64_t key, std::uint32_t step)
{
    auto slot = static_cast<std::size_t>(key & table_mask);
    while (steps[slot] != 0) {
        if (keys[slot] == key) return;
        slot = (slot + 1) & table_mask;
    }
    keys[slot] = key;
    steps[slot] = step + 1;
}

std::int64_t find_baby(const std::vector<std::uint64_t>& keys,
                       const std::vector<std::uint32_t>& steps, std::uint64_t key)
{
    auto slot = static_cast<std::size_t>(key & table_mask);
    while (steps[slot] != 0) {
        if (keys[slot] == key) return static_cast<std::int64_t>(steps[slot] - 1);
        slot = (slot + 1) & table_mask;
    }
    return -1;
}

std::int64_t coprime_log(std::uint64_t x, std::uint64_t y, std::uint64_t modulus)
{
    if (y == 1 % modulus) return 0;
    const auto width = ceil_sqrt(modulus);
    std::vector<std::uint64_t> keys(table_size, 0);
    std::vector<std::uint32_t> steps(table_size, 0);
    std::uint64_t residue = 1 % modulus;
    for (std::uint64_t step = 0; step < width; ++step) {
        insert_baby(keys, steps, residue, static_cast<std::uint32_t>(step));
        residue = (residue * x) % modulus;
    }
    const auto inverse = inverse_mod(x, modulus);
    const auto giant_factor = pow_mod(static_cast<std::uint64_t>(inverse), width, modulus);
    auto giant = y;
    for (std::uint64_t block = 0; block * width <= modulus; ++block) {
        const auto baby = find_baby(keys, steps, giant);
        if (baby >= 0) {
            const auto answer = block * width + static_cast<std::uint64_t>(baby);
            return answer <= modulus ? static_cast<std::int64_t>(answer) : -1;
        }
        giant = (giant * giant_factor) % modulus;
    }
    return -1;
}

std::uint64_t gcd_u64(std::uint64_t left, std::uint64_t right)
{
    return std::gcd(left, right);
}

std::int64_t extended_log(std::uint64_t x, std::uint64_t y, std::uint64_t modulus)
{
    if (modulus == 1) return 0;
    std::uint64_t accumulator = 1, added = 0;
    while (gcd_u64(x, modulus) > 1) {
        const auto divisor = gcd_u64(x, modulus);
        if (y == accumulator) return static_cast<std::int64_t>(added);
        if (y % divisor != 0) return -1;
        y /= divisor;
        modulus /= divisor;
        accumulator = (accumulator * (x / divisor)) % modulus;
        ++added;
        if (modulus == 1) return static_cast<std::int64_t>(added);
    }
    const auto inverse = inverse_mod(accumulator, modulus);
    if (inverse < 0) return -1;
    const auto reduced_target = (y * static_cast<std::uint64_t>(inverse)) % modulus;
    const auto remaining = coprime_log(x % modulus, reduced_target, modulus);
    return remaining < 0 ? -1 : static_cast<std::int64_t>(added) + remaining;
}
} // namespace

extern "C" std::int64_t discrete_logarithm_mod(const std::int64_t* values, std::size_t length)
{
    if (values == nullptr || length != 3) return -1;
    if (values[0] < 0 || values[1] < 0 || values[2] < 1 ||
        static_cast<std::uint64_t>(values[2]) > max_modulus ||
        values[0] >= values[2] || values[1] >= values[2]) return -1;
    return extended_log(static_cast<std::uint64_t>(values[0]),
                        static_cast<std::uint64_t>(values[1]),
                        static_cast<std::uint64_t>(values[2]));
}
