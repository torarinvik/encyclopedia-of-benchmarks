#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 64;
constexpr std::size_t kMaxInput = 3 + 4 * kMaxN;
constexpr std::size_t kMaxParseable = kMaxInput + 1;
constexpr std::size_t kMaxOutputWords = 3 * kMaxN + 2;
constexpr std::int64_t kScale = 1'000'000;

void store_le(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        out[at + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t splash2_water_nsquared(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > kMaxParseable) return -1;
    const auto n_raw = input[0], grid = input[1], radius = input[2];
    if (n_raw < 0 || n_raw > static_cast<std::int64_t>(kMaxN) ||
        grid < 1 || grid > 8 || radius < 1 || radius > 4) return -1;
    const auto n = static_cast<std::size_t>(n_raw);
    if (length != 3 + 4 * n) return -1;
    const std::int64_t side = grid * radius, radius2 = radius * radius;
    std::array<std::int64_t, kMaxN> x{}, y{}, z{}, charge{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto at = 3 + 4 * i;
        x[i] = input[at]; y[i] = input[at + 1]; z[i] = input[at + 2]; charge[i] = input[at + 3];
        if (x[i] < 0 || x[i] >= side || y[i] < 0 || y[i] >= side ||
            z[i] < 0 || z[i] >= side || charge[i] < -4 || charge[i] > 4) return -1;
    }
    std::array<std::array<std::int64_t, 3>, kMaxN> force{};
    std::int64_t energy = 0, pairs = 0;
    for (std::size_t i = 0; i < n; ++i) for (std::size_t j = i + 1; j < n; ++j) {
        const auto dx = x[j] - x[i], dy = y[j] - y[i], dz = z[j] - z[i];
        const auto r2 = dx * dx + dy * dy + dz * dz;
        if (r2 >= radius2) continue;
        const auto product = charge[i] * charge[j];
        energy += (product * (radius2 - r2) * kScale) / ((1 + r2) * (1 + radius2));
        const auto denominator = (1 + r2) * (1 + r2);
        const std::array<std::int64_t, 3> pair_force{
            (-2 * product * dx * kScale) / denominator,
            (-2 * product * dy * kScale) / denominator,
            (-2 * product * dz * kScale) / denominator};
        for (std::size_t axis = 0; axis < 3; ++axis) {
            force[i][axis] += pair_force[axis];
            force[j][axis] -= pair_force[axis];
        }
        ++pairs;
    }
    const auto words = 3 * n + 2, bytes = 8 * words;
    if (output == nullptr || capacity < bytes) return -2;
    std::array<std::int64_t, kMaxOutputWords> result{};
    for (std::size_t i = 0; i < n; ++i)
        for (std::size_t axis = 0; axis < 3; ++axis) result[3 * i + axis] = force[i][axis];
    result[3 * n] = energy; result[3 * n + 1] = pairs;
    for (std::size_t word = 0; word < words; ++word) store_le(output, 8 * word, result[word]);
    return static_cast<std::int64_t>(bytes);
}
