#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_n = 2147483647;
std::uint64_t next_word(std::uint64_t& state) noexcept {
    state += UINT64_C(0x9E3779B97F4A7C15);
    auto z = state;
    z = (z ^ (z >> 30)) * UINT64_C(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)) * UINT64_C(0x94D049BB133111EB);
    return z ^ (z >> 31);
}
std::int64_t mod_power(std::int64_t base, std::int64_t exponent, std::int64_t modulus) noexcept {
    std::int64_t result = 1;
    while (exponent > 0) {
        if (exponent & 1) result = (result * base) % modulus;
        base = (base * base) % modulus;
        exponent >>= 1;
    }
    return result;
}
bool passes_witness(std::int64_t n, std::int64_t a, std::int64_t d, std::int64_t powers_of_two) noexcept {
    auto x = mod_power(a, d, n);
    if (x == 1 || x == n - 1) return true;
    for (std::int64_t round = 1; round < powers_of_two; ++round) {
        x = (x * x) % n;
        if (x == n - 1) return true;
    }
    return false;
}
}

extern "C" std::int64_t miller_rabin_primality_checker(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 3 || length > 4) return -1;
    const auto n = values[0], rounds = values[1], seed = values[2];
    if (length != 3 || n < 5 || n > max_n || (n & 1) == 0 || rounds < 1 || rounds > 64 || seed < 0 || seed > max_n) return -1;
    auto state = static_cast<std::uint64_t>(seed);
    const auto span = static_cast<std::uint64_t>(n - 4);
    const auto threshold = (std::uint64_t{0} - span) % span;
    std::uint64_t word;
    do { word = next_word(state); } while (word < threshold);
    const auto a = 2 + static_cast<std::int64_t>(word % span);
    auto d = n - 1;
    std::int64_t powers_of_two = 0;
    while ((d & 1) == 0) { d >>= 1; ++powers_of_two; }
    for (std::int64_t i = 0; i < rounds; ++i)
        if (!passes_witness(n, a, d, powers_of_two)) return 0;
    return 1;
}
