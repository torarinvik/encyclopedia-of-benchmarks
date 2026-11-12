#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_target = 127;
constexpr std::size_t max_output_bytes = 8 * (max_target + 1);

std::size_t build_path(std::size_t target, std::size_t* path) noexcept {
    if (target == 1) { path[0] = 1; return 1; }
    std::size_t parent[max_target + 1]{};
    bool seen[max_target + 1]{};
    std::size_t queue[max_target + 1]{};
    std::size_t reverse[max_target + 1]{};
    std::size_t head = 0, tail = 1;
    queue[0] = 1;
    seen[1] = true;
    while (head < tail) {
        const std::size_t current = queue[head++];
        std::size_t chain_length = 0;
        for (std::size_t node = current; node != 0; node = parent[node]) reverse[chain_length++] = node;
        for (std::size_t offset = 0; offset < chain_length; ++offset) {
            const std::size_t ancestor = reverse[chain_length - offset - 1];
            const std::size_t child = current + ancestor;
            if (child > target || seen[child]) continue;
            seen[child] = true;
            parent[child] = current;
            if (child == target) {
                std::size_t count = 0;
                for (std::size_t node = target; node != 0; node = parent[node]) path[count++] = node;
                for (std::size_t left = 0, right = count - 1; left < right; ++left, --right) {
                    const auto temporary = path[left]; path[left] = path[right]; path[right] = temporary;
                }
                return count;
            }
            queue[tail++] = child;
        }
    }
    return 0;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t knuth_power_tree(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 1 || input[0] < 1 || input[0] > static_cast<std::int64_t>(max_target)) return -1;
    const auto target = static_cast<std::size_t>(input[0]);
    std::size_t path[max_target]{};
    const auto path_length = build_path(target, path);
    const auto required = 8 * (path_length + 1);
    if (output == nullptr || capacity < required) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(path_length - 1));
    for (std::size_t index = 0; index < path_length; ++index)
        store_i64_le(output, 8 * (index + 1), static_cast<std::int64_t>(path[index]));
    return static_cast<std::int64_t>(required);
}
