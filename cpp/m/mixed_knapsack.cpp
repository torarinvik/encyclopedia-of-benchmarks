/* Clean-room heterogeneous-mode knapsack. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_types = 16;
constexpr std::size_t max_capacity = 64;
constexpr std::size_t max_input = 67;
}

extern "C" std::int64_t mixed_knapsack(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 2 || length > max_input) return -1;
    const auto n_value = input[0];
    const auto capacity_value = input[1];
    if (n_value < 0 || n_value > static_cast<std::int64_t>(max_types)
        || capacity_value < 0 || capacity_value > static_cast<std::int64_t>(max_capacity)) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    const auto capacity = static_cast<std::size_t>(capacity_value);
    if (length != 2 + 4 * n) return -1;
    for (std::size_t item = 0; item < n; ++item) {
        const auto mode = input[2 + 4 * item];
        const auto weight = input[3 + 4 * item];
        const auto value = input[4 + 4 * item];
        const auto limit = input[5 + 4 * item];
        if (mode < 0 || mode > 2 || weight < 1 || weight > 16 || value < 0 || value > 100) return -1;
        if ((mode == 0 && limit != 1) || (mode == 1 && limit != 0)
            || (mode == 2 && (limit < 0 || limit > 16))) return -1;
    }

    std::int64_t best[max_capacity + 1]{};
    for (std::size_t item = 0; item < n; ++item) {
        const auto mode = input[2 + 4 * item];
        const auto weight = static_cast<std::size_t>(input[3 + 4 * item]);
        const auto value = input[4 + 4 * item];
        if (mode == 0) {
            for (auto cap = capacity; cap >= weight; --cap) {
                const auto candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
                if (cap == weight) break;
            }
        } else if (mode == 1) {
            for (std::size_t cap = weight; cap <= capacity; ++cap) {
                const auto candidate = best[cap - weight] + value;
                if (candidate > best[cap]) best[cap] = candidate;
            }
        } else {
            auto remaining = static_cast<std::size_t>(input[5 + 4 * item]);
            std::size_t bundle_size = 1;
            while (remaining > 0) {
                const auto copies = bundle_size < remaining ? bundle_size : remaining;
                const auto bundle_weight = copies * weight;
                const auto bundle_value = static_cast<std::int64_t>(copies) * value;
                if (bundle_weight <= capacity) {
                    for (auto cap = capacity; cap >= bundle_weight; --cap) {
                        const auto candidate = best[cap - bundle_weight] + bundle_value;
                        if (candidate > best[cap]) best[cap] = candidate;
                        if (cap == bundle_weight) break;
                    }
                }
                remaining -= copies;
                bundle_size *= 2;
            }
        }
    }
    return best[capacity];
}
