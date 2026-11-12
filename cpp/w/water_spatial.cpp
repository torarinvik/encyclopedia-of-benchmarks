#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxMolecules = 64;
constexpr std::size_t kMaxGridSide = 8;
constexpr std::size_t kMaxInputLength = 4 + 4 * kMaxMolecules;
constexpr std::size_t kMaxCells = 512;
constexpr std::int64_t kScale = 1'000'000;

std::int64_t trunc_div(std::int64_t numerator, std::int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t water_spatial(const std::int64_t* input, std::size_t length,
                                       std::uint8_t* output, std::size_t capacity) {
    if (!input || length < 3 || length > kMaxInputLength) return -1;
    const auto count_value = input[0], grid_value = input[1], cutoff_value = input[2];
    if (count_value < 0 || count_value > static_cast<std::int64_t>(kMaxMolecules)
            || grid_value < 1 || grid_value > static_cast<std::int64_t>(kMaxGridSide)
            || cutoff_value < 1 || cutoff_value > 4) return -1;
    const auto count = static_cast<std::size_t>(count_value);
    const auto grid = static_cast<int>(grid_value), cutoff = static_cast<int>(cutoff_value);
    if (length != 3 + 4 * count) return -1;
    const int extent = grid * cutoff;
    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 3 + 4 * i;
        if (input[base] < 0 || input[base] >= extent
                || input[base + 1] < 0 || input[base + 1] >= extent
                || input[base + 2] < 0 || input[base + 2] >= extent
                || input[base + 3] < -4 || input[base + 3] > 4) return -1;
    }
    const auto output_bytes = 8 * (3 * count + 2);
    if (!output || capacity < output_bytes) return -2;

    std::array<std::int64_t, kMaxCells> head;
    std::array<std::int64_t, kMaxMolecules> next{};
    std::array<std::int64_t, kMaxMolecules> fx{}, fy{}, fz{};
    head.fill(-1);
    for (std::size_t i = 0; i < count; ++i) {
        const auto base = 3 + 4 * i;
        const int cx = static_cast<int>(input[base] / cutoff);
        const int cy = static_cast<int>(input[base + 1] / cutoff);
        const int cz = static_cast<int>(input[base + 2] / cutoff);
        const int cell = cx + grid * (cy + grid * cz);
        next[i] = head[cell];
        head[cell] = static_cast<std::int64_t>(i);
    }

    std::int64_t energy = 0, pairs = 0;
    const std::int64_t cutoff_squared = static_cast<std::int64_t>(cutoff) * cutoff;
    for (std::size_t i = 0; i < count; ++i) {
        const auto base_i = 3 + 4 * i;
        const int cx = static_cast<int>(input[base_i] / cutoff);
        const int cy = static_cast<int>(input[base_i + 1] / cutoff);
        const int cz = static_cast<int>(input[base_i + 2] / cutoff);
        for (int oz = -1; oz <= 1; ++oz) {
            const int nz = cz + oz;
            if (nz < 0 || nz >= grid) continue;
            for (int oy = -1; oy <= 1; ++oy) {
                const int ny = cy + oy;
                if (ny < 0 || ny >= grid) continue;
                for (int ox = -1; ox <= 1; ++ox) {
                    const int nx = cx + ox;
                    if (nx < 0 || nx >= grid) continue;
                    const int cell = nx + grid * (ny + grid * nz);
                    for (auto candidate = head[cell]; candidate >= 0; candidate = next[candidate]) {
                        const auto j = static_cast<std::size_t>(candidate);
                        if (j <= i) continue;
                        const auto base_j = 3 + 4 * j;
                        const auto dx = input[base_j] - input[base_i];
                        const auto dy = input[base_j + 1] - input[base_i + 1];
                        const auto dz = input[base_j + 2] - input[base_i + 2];
                        const auto r2 = dx * dx + dy * dy + dz * dz;
                        if (r2 >= cutoff_squared) continue;
                        const auto product = input[base_i + 3] * input[base_j + 3];
                        energy += trunc_div(product * (cutoff_squared - r2) * kScale,
                                            (1 + r2) * (1 + cutoff_squared));
                        const auto denominator = (1 + r2) * (1 + r2);
                        const auto pair_x = trunc_div(-2 * product * dx * kScale, denominator);
                        const auto pair_y = trunc_div(-2 * product * dy * kScale, denominator);
                        const auto pair_z = trunc_div(-2 * product * dz * kScale, denominator);
                        fx[i] += pair_x; fx[j] -= pair_x;
                        fy[i] += pair_y; fy[j] -= pair_y;
                        fz[i] += pair_z; fz[j] -= pair_z;
                        ++pairs;
                    }
                }
            }
        }
    }
    for (std::size_t i = 0; i < count; ++i) {
        store_i64_le(output, 8 * (3 * i), fx[i]);
        store_i64_le(output, 8 * (3 * i + 1), fy[i]);
        store_i64_le(output, 8 * (3 * i + 2), fz[i]);
    }
    store_i64_le(output, 8 * (3 * count), energy);
    store_i64_le(output, 8 * (3 * count + 1), pairs);
    return static_cast<std::int64_t>(output_bytes);
}
