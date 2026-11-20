#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxItems = 16;
constexpr std::size_t kMaxCapacity = 32;
constexpr std::size_t kMaxInputLength = 19;
constexpr std::size_t kStride = kMaxCapacity + 1;
} // namespace

extern "C" std::int64_t subset_sum_bin_packing(const std::int64_t *input,
                                                 std::size_t length) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInputLength) return -1;
    const std::int64_t raw_count = input[0];
    const std::int64_t raw_capacity = input[1];
    if (raw_count < 1 || raw_count > static_cast<std::int64_t>(kMaxItems) ||
        raw_capacity < 1 || raw_capacity > static_cast<std::int64_t>(kMaxCapacity)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);
    const auto capacity = static_cast<std::size_t>(raw_capacity);
    if (length != 2 + count) return -1;

    std::int64_t remaining_size[kMaxItems]{};
    std::size_t remaining_item[kMaxItems]{};
    std::int64_t assigned_bin[kMaxItems]{};
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t size = input[2 + i];
        if (size < 1 || size > raw_capacity) return -1;
        remaining_size[i] = size;
        remaining_item[i] = i;
    }

    std::size_t remaining_count = count;
    std::int64_t bin_count = 0;
    while (remaining_count > 0) {
        bool reachable[kMaxItems + 1][kStride]{};
        reachable[remaining_count][0] = true;
        for (std::size_t i = remaining_count; i > 0; --i) {
            const std::size_t item = i - 1;
            const auto size = static_cast<std::size_t>(remaining_size[item]);
            for (std::size_t sum = 0; sum <= capacity; ++sum) {
                reachable[item][sum] = reachable[item + 1][sum];
                if (sum >= size && reachable[item + 1][sum - size])
                    reachable[item][sum] = true;
            }
        }

        std::size_t target = capacity;
        while (target > 0 && !reachable[0][target]) --target;
        bool selected[kMaxItems]{};
        std::size_t needed = target;
        for (std::size_t item = 0; item < remaining_count; ++item) {
            const auto size = static_cast<std::size_t>(remaining_size[item]);
            if (size <= needed && reachable[item + 1][needed - size]) {
                selected[item] = true;
                needed -= size;
                assigned_bin[remaining_item[item]] = bin_count;
            }
        }

        std::size_t survivors = 0;
        for (std::size_t item = 0; item < remaining_count; ++item) {
            if (!selected[item]) {
                remaining_size[survivors] = remaining_size[item];
                remaining_item[survivors] = remaining_item[item];
                ++survivors;
            }
        }
        remaining_count = survivors;
        ++bin_count;
    }

    std::int64_t checksum = bin_count * 10000;
    for (std::size_t i = 0; i < count; ++i)
        checksum += static_cast<std::int64_t>(i + 1) * (assigned_bin[i] + 1);
    return checksum;
}
