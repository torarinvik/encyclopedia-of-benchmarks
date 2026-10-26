#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxLeaves = 8;
constexpr std::size_t kMaxEdges = 13;
constexpr std::size_t kMaxInput = 27;

void store_i64_le(std::uint8_t *output, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::size_t bit_count(std::uint64_t value, std::size_t n)
{
    std::size_t count = 0;
    for (std::size_t bit = 0; bit < n; ++bit) count += static_cast<std::size_t>((value >> bit) & 1U);
    return count;
}

bool valid_tree(const std::int64_t *input, std::size_t offset, std::size_t n, std::size_t edges)
{
    std::uint64_t masks[kMaxEdges]{};
    std::uint64_t internal[kMaxEdges]{};
    std::size_t internal_count = 0;
    const auto universe = (std::uint64_t{1} << n) - 1;
    for (std::size_t edge = 0; edge < edges; ++edge) {
        const auto raw = input[offset + edge];
        if (raw <= 0 || static_cast<std::uint64_t>(raw) >= universe || (raw & 1) != 0) return false;
        masks[edge] = static_cast<std::uint64_t>(raw);
        for (std::size_t earlier = 0; earlier < edge; ++earlier) if (masks[earlier] == masks[edge]) return false;
        const auto size = bit_count(masks[edge], n);
        if (size == 1 || size == n - 1) {
            if (size == n - 1 && masks[edge] != (universe ^ 1U)) return false;
        } else if (size >= 2 && size <= n - 2) {
            internal[internal_count++] = masks[edge];
        } else {
            return false;
        }
    }
    if (internal_count != n - 3) return false;
    for (std::size_t leaf = 1; leaf < n; ++leaf) {
        const auto pendant = std::uint64_t{1} << leaf;
        std::size_t found = 0;
        for (std::size_t edge = 0; edge < edges; ++edge) found += static_cast<std::size_t>(masks[edge] == pendant);
        if (found != 1) return false;
    }
    std::size_t root_pendant = 0;
    for (std::size_t edge = 0; edge < edges; ++edge) root_pendant += static_cast<std::size_t>(masks[edge] == (universe ^ 1U));
    if (root_pendant != 1) return false;
    for (std::size_t i = 0; i < internal_count; ++i) {
        for (std::size_t j = i + 1; j < internal_count; ++j) {
            const auto intersection = internal[i] & internal[j];
            if (intersection != 0 && intersection != internal[i] && intersection != internal[j]) return false;
        }
    }
    return true;
}
}

extern "C" std::int64_t non_shared_edges(const std::int64_t *input, std::size_t length,
                                           std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 7 || length > kMaxInput) return -1;
    const auto leaf_value = input[0];
    if (leaf_value < 3 || leaf_value > static_cast<std::int64_t>(kMaxLeaves)) return -1;
    const auto leaves = static_cast<std::size_t>(leaf_value);
    const auto edges = 2 * leaves - 3;
    if (length != 1 + 2 * edges) return -1;
    const auto second = 1 + edges;
    if (!valid_tree(input, 1, leaves, edges) || !valid_tree(input, second, leaves, edges)) return -1;
    std::int64_t shared = 0;
    for (std::size_t left = 0; left < edges; ++left) {
        for (std::size_t right = 0; right < edges; ++right) {
            if (input[1 + left] == input[second + right]) { ++shared; break; }
        }
    }
    if (output == nullptr || capacity < 8) return -2;
    std::uint8_t staged[8]{};
    store_i64_le(staged, static_cast<std::int64_t>(edges) - shared);
    for (std::size_t byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
