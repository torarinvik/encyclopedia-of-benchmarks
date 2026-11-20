#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_parseable_length = 6;
constexpr std::int64_t max_denominations = 4;
constexpr std::int64_t max_denomination = 16;
constexpr std::int64_t distance_inf = 1'000'000;

std::int64_t gcd_i64(std::int64_t left, std::int64_t right) noexcept {
    while (right != 0) {
        const auto remainder = left % right;
        left = right;
        right = remainder;
    }
    return left;
}

std::int64_t apery_frobenius(const std::int64_t* coins, std::int64_t count,
                             std::int64_t modulus) noexcept {
    std::array<std::int64_t, 16> distance{};
    std::array<bool, 16> settled{};
    distance.fill(distance_inf);
    distance[0] = 0;
    for (std::int64_t step = 0; step < modulus; ++step) {
        std::int64_t source = -1;
        auto best = distance_inf;
        for (std::int64_t residue = 0; residue < modulus; ++residue) {
            if (!settled[residue] && distance[residue] < best) {
                source = residue;
                best = distance[residue];
            }
        }
        if (source < 0) return -1;
        settled[source] = true;
        for (std::int64_t index = 0; index < count; ++index) {
            const auto coin = coins[index];
            const auto target = (source + coin) % modulus;
            const auto candidate = best + coin;
            if (candidate < distance[target]) distance[target] = candidate;
        }
    }
    std::int64_t maximum = 0;
    for (std::int64_t residue = 0; residue < modulus; ++residue) {
        if (distance[residue] > maximum) maximum = distance[residue];
    }
    return maximum - modulus;
}

std::int64_t solve(const std::int64_t* input, std::size_t length) noexcept {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const auto count = input[0];
    if (count < 2 || count > max_denominations || length != static_cast<std::size_t>(count + 1)) return -1;
    std::int64_t common = 0;
    auto minimum = max_denomination + 1;
    for (std::int64_t index = 0; index < count; ++index) {
        const auto coin = input[index + 1];
        if (coin < 2 || coin > max_denomination) return -1;
        for (std::int64_t previous = 0; previous < index; ++previous) {
            if (coin == input[previous + 1]) return -1;
        }
        common = gcd_i64(common, coin);
        if (coin < minimum) minimum = coin;
    }
    if (common != 1) return -1;
    return apery_frobenius(input + 1, count, minimum);
}
}

extern "C" std::int64_t frobenius_number_apery(const std::int64_t* input,
                                                std::size_t length) noexcept {
    return solve(input, length);
}
