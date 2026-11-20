#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxSide = 8;
constexpr std::size_t kMaxRays = 16;
constexpr std::size_t kMaxSamples = 32;
constexpr std::size_t kMaxVoxels = kMaxSide * kMaxSide * kMaxSide;
constexpr std::size_t kMaxInput = 3 + 2 * kMaxVoxels + 6 * kMaxRays;
constexpr std::size_t kMaxParseable = kMaxInput + 1;
constexpr std::size_t kMaxMaskBytes = 4 * kMaxVoxels;
constexpr std::int64_t kQ8 = 256;
constexpr std::int64_t kQ16 = 65'536;
constexpr std::int64_t kWeightDen = 16'777'216;
constexpr std::int64_t kAlphaDen = 255 * kWeightDen;
constexpr std::int64_t kColorDen = 255 * 255 * kWeightDen;

std::size_t voxel_index(int side, int x, int y, int z) {
    return (static_cast<std::size_t>(z) * side + y) * side + x;
}

std::size_t mask_index(int level, int x, int y, int z) {
    return (((static_cast<std::size_t>(level) * kMaxSide + z) * kMaxSide + y) * kMaxSide + x);
}

std::int64_t round_half_up(std::int64_t n, std::int64_t d) { return (n + d / 2) / d; }

std::uint8_t to_byte(std::int64_t q) {
    return static_cast<std::uint8_t>((q * 255 + kQ16 / 2) / kQ16);
}

void interpolate(int side, const std::array<std::uint8_t, kMaxVoxels>& alpha,
                 const std::array<std::uint8_t, kMaxVoxels>& gray,
                 std::int64_t xq, std::int64_t yq, std::int64_t zq,
                 std::int64_t& opacity_q16, std::int64_t& premul_gray_q16) {
    const int low[3] = {static_cast<int>(xq / kQ8), static_cast<int>(yq / kQ8), static_cast<int>(zq / kQ8)};
    const int frac[3] = {static_cast<int>(xq % kQ8), static_cast<int>(yq % kQ8), static_cast<int>(zq % kQ8)};
    const int high[3] = {low[0] + (low[0] + 1 < side), low[1] + (low[1] + 1 < side), low[2] + (low[2] + 1 < side)};
    std::int64_t opacity_sum = 0, premul_sum = 0;
    for (int dz = 0; dz < 2; ++dz) for (int dy = 0; dy < 2; ++dy) for (int dx = 0; dx < 2; ++dx) {
        const int x = dx ? high[0] : low[0], y = dy ? high[1] : low[1], z = dz ? high[2] : low[2];
        const std::int64_t wx = dx ? frac[0] : kQ8 - frac[0];
        const std::int64_t wy = dy ? frac[1] : kQ8 - frac[1];
        const std::int64_t wz = dz ? frac[2] : kQ8 - frac[2];
        const std::size_t at = voxel_index(side, x, y, z);
        const std::int64_t weight = wx * wy * wz;
        opacity_sum += static_cast<std::int64_t>(alpha[at]) * weight;
        premul_sum += static_cast<std::int64_t>(alpha[at]) * gray[at] * weight;
    }
    opacity_q16 = round_half_up(opacity_sum * kQ16, kAlphaDen);
    premul_gray_q16 = round_half_up(premul_sum * kQ16, kColorDen);
}
}

extern "C" std::int64_t splash2_volrend_raymarch(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length < 3 || length > kMaxParseable) return -1;
    const std::int64_t side_raw = input[0], rays_raw = input[1], samples_raw = input[2];
    if ((side_raw != 2 && side_raw != 4 && side_raw != 8) || rays_raw < 1 || rays_raw > 16 ||
        samples_raw < 1 || samples_raw > 32) return -1;
    const int side = static_cast<int>(side_raw), samples = static_cast<int>(samples_raw);
    const std::size_t ray_count = static_cast<std::size_t>(rays_raw);
    const std::size_t voxel_count = static_cast<std::size_t>(side) * side * side;
    const std::size_t ray_start = 3 + 2 * voxel_count;
    if (length != ray_start + 6 * ray_count) return -1;

    std::array<std::uint8_t, kMaxVoxels> alpha{}, gray{};
    std::array<std::int32_t, 6 * kMaxRays> rays{};
    for (std::size_t voxel = 0; voxel < voxel_count; ++voxel) {
        const auto a = input[3 + 2 * voxel], g = input[4 + 2 * voxel];
        if (a < 0 || a > 255 || g < 0 || g > 255) return -1;
        alpha[voxel] = static_cast<std::uint8_t>(a);
        gray[voxel] = static_cast<std::uint8_t>(g);
    }
    const std::int64_t coordinate_max = (side - 1) * kQ8;
    for (std::size_t ray = 0; ray < ray_count; ++ray) {
        const std::size_t at = ray_start + 6 * ray;
        for (int axis = 0; axis < 3; ++axis) {
            const auto origin = input[at + static_cast<std::size_t>(axis)];
            const auto delta = input[at + static_cast<std::size_t>(axis) + 3];
            if (origin < 0 || origin > coordinate_max || delta < -coordinate_max || delta > coordinate_max) return -1;
            rays[6 * ray + axis] = static_cast<std::int32_t>(origin);
            rays[6 * ray + axis + 3] = static_cast<std::int32_t>(delta);
        }
        if (samples > 1 && rays[6 * ray + 3] == 0 && rays[6 * ray + 4] == 0 && rays[6 * ray + 5] == 0) return -1;
        for (int sample = 0; sample < samples; ++sample) for (int axis = 0; axis < 3; ++axis) {
            const auto q = static_cast<std::int64_t>(rays[6 * ray + axis]) +
                           static_cast<std::int64_t>(sample) * rays[6 * ray + axis + 3];
            if (q < 0 || q > coordinate_max) return -1;
        }
    }

    const std::size_t output_bytes = 5 * ray_count;
    if (output == nullptr) return -2;
    if (capacity < output_bytes) return -3;

    std::array<std::uint8_t, kMaxMaskBytes> support{};
    for (int z = 0; z < side; ++z) for (int y = 0; y < side; ++y) for (int x = 0; x < side; ++x) {
        std::uint8_t occupied = 0;
        for (int dz = 0; dz < 2; ++dz) for (int dy = 0; dy < 2; ++dy) for (int dx = 0; dx < 2; ++dx) {
            const int nx = x + (x + 1 < side && dx), ny = y + (y + 1 < side && dy), nz = z + (z + 1 < side && dz);
            occupied = static_cast<std::uint8_t>(occupied | (alpha[voxel_index(side, nx, ny, nz)] != 0));
        }
        support[mask_index(0, x, y, z)] = occupied;
    }
    int levels = 0;
    for (int dimension = side; dimension > 1; dimension >>= 1) ++levels;
    for (int level = 1; level <= levels; ++level) {
        const int dimension = side >> level;
        for (int z = 0; z < dimension; ++z) for (int y = 0; y < dimension; ++y) for (int x = 0; x < dimension; ++x) {
            std::uint8_t occupied = 0;
            for (int dz = 0; dz < 2; ++dz) for (int dy = 0; dy < 2; ++dy) for (int dx = 0; dx < 2; ++dx)
                occupied = static_cast<std::uint8_t>(occupied | support[mask_index(level - 1, 2 * x + dx, 2 * y + dy, 2 * z + dz)]);
            support[mask_index(level, x, y, z)] = occupied;
        }
    }

    for (std::size_t ray = 0; ray < ray_count; ++ray) {
        std::int64_t accumulated_alpha = 0, accumulated_gray = 0;
        int used = 0;
        for (int sample = 0; sample < samples; ++sample) {
            used = sample + 1;
            const auto xq = static_cast<std::int64_t>(rays[6 * ray]) + static_cast<std::int64_t>(sample) * rays[6 * ray + 3];
            const auto yq = static_cast<std::int64_t>(rays[6 * ray + 1]) + static_cast<std::int64_t>(sample) * rays[6 * ray + 4];
            const auto zq = static_cast<std::int64_t>(rays[6 * ray + 2]) + static_cast<std::int64_t>(sample) * rays[6 * ray + 5];
            const int cell[3] = {static_cast<int>(xq / kQ8), static_cast<int>(yq / kQ8), static_cast<int>(zq / kQ8)};
            bool supported = true;
            for (int level = levels; level >= 0; --level) {
                if (support[mask_index(level, cell[0] >> level, cell[1] >> level, cell[2] >> level)] == 0) {
                    supported = false;
                    break;
                }
            }
            if (supported) {
                std::int64_t sample_alpha, sample_gray;
                interpolate(side, alpha, gray, xq, yq, zq, sample_alpha, sample_gray);
                const auto remaining = kQ16 - accumulated_alpha;
                accumulated_alpha = std::min(kQ16, accumulated_alpha + round_half_up(remaining * sample_alpha, kQ16));
                accumulated_gray = std::min(kQ16, accumulated_gray + round_half_up(remaining * sample_gray, kQ16));
                if (accumulated_alpha == kQ16) break;
            }
        }
        const auto out = 5 * ray;
        const auto value = to_byte(accumulated_gray);
        output[out] = value; output[out + 1] = value; output[out + 2] = value;
        output[out + 3] = to_byte(accumulated_alpha); output[out + 4] = static_cast<std::uint8_t>(used);
    }
    return static_cast<std::int64_t>(output_bytes);
}
