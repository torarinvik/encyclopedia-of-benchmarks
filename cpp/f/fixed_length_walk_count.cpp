// Uncompiled exact-length walk counting draft.
#include <array>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t fixed_length_walk_count(const std::int64_t* input, std::size_t length) {
    constexpr std::int64_t mod = 1000000007;
    if (!input || length < 4 || length > 261) return -1;
    const auto nv = input[0], source = input[2], target = input[3];
    auto k = input[1];
    if (nv < 1 || nv > 16 || k < 0 || k > 1000000000 || source < 0 || source >= nv ||
        target < 0 || target >= nv || length != 4 + static_cast<std::size_t>(nv*nv)) return -1;
    const auto n = static_cast<std::size_t>(nv);
    std::array<std::array<std::int64_t,16>,16> matrix{};
    std::array<std::int64_t,16> vector{};
    for (std::size_t i=0; i<n; ++i) for (std::size_t j=0; j<n; ++j) {
        const auto value = input[4+i*n+j];
        if (value < 0 || value > 100) return -1;
        matrix[i][j] = value;
    }
    vector[static_cast<std::size_t>(source)] = 1;
    while (k > 0) {
        if (k & 1) {
            std::array<std::int64_t,16> next{};
            for (std::size_t i=0; i<n; ++i) for (std::size_t j=0; j<n; ++j)
                next[j] = (next[j] + vector[i]*matrix[i][j]) % mod;
            vector = next;
        }
        k >>= 1;
        if (k > 0) {
            std::array<std::array<std::int64_t,16>,16> next{};
            for (std::size_t i=0; i<n; ++i) for (std::size_t p=0; p<n; ++p)
                for (std::size_t j=0; j<n; ++j)
                    next[i][j] = (next[i][j] + matrix[i][p]*matrix[p][j]) % mod;
            matrix = next;
        }
    }
    return vector[static_cast<std::size_t>(target)];
}
