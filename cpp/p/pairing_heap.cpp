#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items = 128;
constexpr std::size_t max_parseable_input_length = max_items + 2;
constexpr std::uint64_t fnv_offset_basis = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);

struct PairingNode {
    std::int32_t key;
    int first_child;
    int next_sibling;
};

int meld(int first, int second, std::array<PairingNode, max_items> &nodes) {
    if (first < 0) return second;
    if (second < 0) return first;
    if (nodes[second].key < nodes[first].key) {
        const int temporary = first;
        first = second;
        second = temporary;
    }
    nodes[second].next_sibling = nodes[first].first_child;
    nodes[first].first_child = second;
    nodes[first].next_sibling = -1;
    return first;
}

std::uint64_t hash_key(std::uint64_t hash, std::int32_t key) {
    const auto bits = static_cast<std::uint32_t>(key);
    for (unsigned byte = 0; byte < 4; ++byte) {
        hash ^= (bits >> (byte * 8)) & UINT32_C(0xff);
        hash *= fnv_prime;
    }
    return hash;
}
} // namespace

extern "C" std::int64_t pairing_heap(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 1 || length > max_parseable_input_length) return -1;
    const auto raw_count = values[0];
    if (raw_count < 2 || raw_count > static_cast<std::int64_t>(max_items) ||
        length != 1 + static_cast<std::size_t>(raw_count)) return -1;
    const auto count = static_cast<std::size_t>(raw_count);

    std::array<PairingNode, max_items> nodes{};
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = values[1 + i];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        for (std::size_t previous = 0; previous < i; ++previous)
            if (values[1 + previous] == value) return -1;
        nodes[i] = {static_cast<std::int32_t>(value), -1, -1};
    }

    int root = -1;
    for (std::size_t i = 0; i < count; ++i) root = meld(root, static_cast<int>(i), nodes);

    auto hash = fnv_offset_basis;
    for (std::size_t extraction = 0; extraction + 1 < count; ++extraction) {
        const int removed = root;
        hash = hash_key(hash, nodes[removed].key);
        std::array<int, max_items> forest{};
        std::array<int, max_items> paired{};
        std::size_t forest_count = 0;
        int child = nodes[removed].first_child;
        nodes[removed].first_child = -1;
        while (child >= 0) {
            const int next = nodes[child].next_sibling;
            nodes[child].next_sibling = -1;
            forest[forest_count++] = child;
            child = next;
        }
        std::size_t paired_count = 0;
        for (std::size_t i = 0; i < forest_count; i += 2) {
            const int right = i + 1 < forest_count ? forest[i + 1] : -1;
            paired[paired_count++] = meld(forest[i], right, nodes);
        }
        int rebuilt = -1;
        while (paired_count > 0) rebuilt = meld(rebuilt, paired[--paired_count], nodes);
        root = rebuilt;
    }
    return static_cast<std::int64_t>(hash & INT64_MAX);
}
