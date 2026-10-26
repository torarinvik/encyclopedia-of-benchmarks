#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxRays = 5;
constexpr int kMaxRounds = 32;
constexpr std::size_t kMaxInput = 11;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t randomized_ray_search(const std::int64_t *input,
                                                std::size_t length,
                                                std::uint8_t *output,
                                                std::size_t capacity)
{
    if (input == nullptr || length < 5 || length > kMaxInput) return -1;
    const auto rays_raw = input[0], growth = input[1], initial = input[2];
    if (rays_raw < 2 || rays_raw > kMaxRays || growth < 2 || growth > 4
        || initial < 1000 || initial >= growth * 1000 || length != static_cast<std::size_t>(rays_raw) + 5) return -1;
    const int rays = static_cast<int>(rays_raw);
    int permutation[kMaxRays], seen[kMaxRays]{};
    for (int i = 0; i < rays; ++i) {
        const auto ray = input[3 + i];
        if (ray < 0 || ray >= rays || seen[ray]) return -1;
        permutation[i] = static_cast<int>(ray);
        seen[ray] = 1;
    }
    const auto target = input[3 + rays], target_distance = input[4 + rays];
    if (target < 0 || target >= rays || target_distance < 1 || target_distance > 1000000000) return -1;
    auto distance = initial;
    std::int64_t total = 0, attempts = 0;
    bool found = false;
    for (int round = 0; round < kMaxRounds; ++round) {
        const int ray = permutation[round % rays];
        ++attempts;
        if (ray == target && target_distance <= distance) {
            total += target_distance;
            found = true;
            break;
        }
        total += 2 * distance;
        distance *= growth;
    }
    if (!found) return -1;
    if (output == nullptr || capacity < 16) return -2;
    store_i64_le(output, 0, attempts);
    store_i64_le(output, 8, total);
    return 16;
}
