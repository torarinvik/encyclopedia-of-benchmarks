#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int max_n = 512;
constexpr std::int64_t modulus = 998244353;

std::int64_t mod_pow(std::int64_t base, int exponent) {
    std::int64_t result = 1;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * base % modulus;
        base = base * base % modulus;
        exponent >>= 1;
    }
    return result;
}

std::int64_t solve(int n) {
    std::array<std::int64_t, max_n + 1> factorial{};
    std::array<std::int64_t, max_n + 1> inverse_factorial{};
    std::array<std::int64_t, max_n + 1> all_graphs{};
    std::array<std::int64_t, max_n + 1> connected{};
    factorial[0] = 1;
    for (int i = 1; i <= n; ++i) factorial[i] = factorial[i - 1] * i % modulus;
    inverse_factorial[n] = mod_pow(factorial[n], 998244351);
    for (int i = n; i > 0; --i) inverse_factorial[i - 1] = inverse_factorial[i] * i % modulus;

    all_graphs[0] = 1;
    std::int64_t edge_choices = 1;
    for (int size = 1; size <= n; ++size) {
        all_graphs[size] = all_graphs[size - 1] * edge_choices % modulus;
        edge_choices = edge_choices * 2 % modulus;
    }
    connected[1] = 1;
    for (int size = 2; size <= n; ++size) {
        std::int64_t disconnected = 0;
        for (int component_size = 1; component_size < size; ++component_size) {
            auto choose = factorial[size - 1] * inverse_factorial[component_size - 1] % modulus;
            choose = choose * inverse_factorial[size - component_size] % modulus;
            auto term = choose * connected[component_size] % modulus;
            term = term * all_graphs[size - component_size] % modulus;
            disconnected = (disconnected + term) % modulus;
        }
        connected[size] = (all_graphs[size] - disconnected + modulus) % modulus;
    }
    return connected[n];
}
}

extern "C" std::int64_t connected_labeled_graph_count(const std::int64_t* input,
        std::size_t length) noexcept {
    if (!input || length != 1 || input[0] < 1 || input[0] > max_n) return -1;
    return solve(static_cast<int>(input[0]));
}
