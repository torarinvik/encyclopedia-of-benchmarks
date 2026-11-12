#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxN = 48;
constexpr std::size_t kMaxNodes = 2 * kMaxN - 1;
constexpr std::size_t kGrid = kMaxN * kMaxN;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255u);
        bits >>= 8;
    }
}

bool intervals_overlap(int left_a, int right_a, int left_b, int right_b) {
    return (left_a < left_b && left_b <= right_a && right_a < right_b) ||
           (left_b < left_a && left_a <= right_b && right_b < right_a);
}
}

extern "C" std::int64_t common_interval_decomposition_tree(
    const std::int64_t *input, std::size_t length, std::uint8_t *output,
    std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 1 + kMaxN) return -1;
    if (input[0] < 1 || input[0] > static_cast<std::int64_t>(kMaxN)) return -1;
    const auto n = static_cast<std::size_t>(input[0]);
    if (length != n + 1) return -1;

    std::array<bool, kMaxN> seen{};
    for (std::size_t i = 0; i < n; ++i) {
        const auto value = input[i + 1];
        if (value < 0 || value >= static_cast<std::int64_t>(n) || seen[value]) return -1;
        seen[value] = true;
    }

    std::array<bool, kGrid> connected{};
    auto strong = std::array<bool, kGrid>{};
    for (std::size_t left = 0; left < n; ++left) {
        std::int64_t minimum = static_cast<std::int64_t>(n);
        std::int64_t maximum = -1;
        for (std::size_t right = left; right < n; ++right) {
            const auto value = input[right + 1];
            if (value < minimum) minimum = value;
            if (value > maximum) maximum = value;
            const auto slot = left * kMaxN + right;
            if (maximum - minimum == static_cast<std::int64_t>(right - left)) {
                connected[slot] = true;
                strong[slot] = true;
            }
        }
    }

    for (std::size_t left_a = 0; left_a < n; ++left_a) {
        for (std::size_t right_a = left_a; right_a < n; ++right_a) {
            const auto slot_a = left_a * kMaxN + right_a;
            if (!connected[slot_a]) continue;
            for (std::size_t left_b = 0; left_b < n; ++left_b) {
                for (std::size_t right_b = left_b; right_b < n; ++right_b) {
                    const auto slot_b = left_b * kMaxN + right_b;
                    if (slot_b <= slot_a || !connected[slot_b]) continue;
                    if (intervals_overlap(static_cast<int>(left_a), static_cast<int>(right_a),
                                          static_cast<int>(left_b), static_cast<int>(right_b))) {
                        strong[slot_a] = false;
                        strong[slot_b] = false;
                    }
                }
            }
        }
    }

    std::array<int, kMaxNodes> node_left{};
    std::array<int, kMaxNodes> node_right{};
    std::array<int, kMaxNodes> parent{};
    std::array<int, kMaxNodes> node_type{};
    std::size_t node_count = 0;
    for (std::size_t span = n; span > 0; --span) {
        for (std::size_t left = 0; left + span <= n; ++left) {
            const auto right = left + span - 1;
            if (!strong[left * kMaxN + right]) continue;
            node_left[node_count] = static_cast<int>(left);
            node_right[node_count] = static_cast<int>(right);
            ++node_count;
        }
    }
    if (node_count == 0 || node_count > kMaxNodes) return -1;

    for (std::size_t node = 0; node < node_count; ++node) {
        const int span = node_right[node] - node_left[node] + 1;
        int best_span = static_cast<int>(n) + 1;
        parent[node] = -1;
        for (std::size_t candidate = 0; candidate < node_count; ++candidate) {
            const int candidate_span = node_right[candidate] - node_left[candidate] + 1;
            if (candidate_span > span && candidate_span < best_span &&
                node_left[candidate] <= node_left[node] &&
                node_right[node] <= node_right[candidate]) {
                parent[node] = static_cast<int>(candidate);
                best_span = candidate_span;
            }
        }
    }

    for (std::size_t node = 0; node < node_count; ++node) {
        std::array<int, kMaxN> children{};
        std::size_t child_count = 0;
        for (std::size_t child = 0; child < node_count; ++child) {
            if (parent[child] != static_cast<int>(node)) continue;
            std::size_t at = child_count;
            while (at > 0 && node_left[children[at - 1]] > node_left[child]) {
                children[at] = children[at - 1];
                --at;
            }
            children[at] = static_cast<int>(child);
            ++child_count;
        }

        node_type[node] = 0;
        for (std::size_t first = 0; first < child_count && node_type[node] == 0; ++first) {
            for (std::size_t last = first; last < child_count; ++last) {
                const int left = node_left[children[first]];
                const int right = node_right[children[last]];
                std::int64_t minimum = static_cast<std::int64_t>(n);
                std::int64_t maximum = -1;
                for (int position = left; position <= right; ++position) {
                    const auto value = input[static_cast<std::size_t>(position) + 1];
                    if (value < minimum) minimum = value;
                    if (value > maximum) maximum = value;
                }
                if (maximum - minimum != static_cast<std::int64_t>(right - left)) {
                    node_type[node] = 1;
                    break;
                }
            }
        }
    }

    const auto output_bytes = (1 + 4 * node_count) * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    store_i64_le(output, 0, static_cast<std::int64_t>(node_count));
    for (std::size_t node = 0; node < node_count; ++node) {
        const auto offset = 8 + 32 * node;
        store_i64_le(output, offset, static_cast<std::int64_t>(parent[node]));
        store_i64_le(output, offset + 8, node_left[node]);
        store_i64_le(output, offset + 16, node_right[node]);
        store_i64_le(output, offset + 24, node_type[node]);
    }
    return static_cast<std::int64_t>(output_bytes);
}
