/* Bounded Van Emde Boas set adapted from TheAlgorithms/Rust. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_COUNT = 256;
constexpr std::size_t MAX_INPUT_VALUES = 771;
constexpr std::size_t MAX_OUTPUT_BYTES = 1024;
constexpr std::size_t MAX_TREE_NODES = 358;
constexpr std::size_t MAX_CLUSTERS = 16;

struct VebNode {
    std::uint16_t universe = 0;
    std::uint8_t low_bits = 0;
    std::uint8_t cluster_count = 0;
    std::int32_t minimum = -1;
    std::int32_t maximum = 0;
    std::int32_t summary = -1;
    std::int32_t clusters[MAX_CLUSTERS]{};
};

std::int32_t initialize(VebNode *nodes, std::size_t &next, std::uint32_t universe)
{
    const auto id = static_cast<std::int32_t>(next++);
    nodes[id].universe = static_cast<std::uint16_t>(universe);
    nodes[id].low_bits = 0;
    nodes[id].cluster_count = 0;
    nodes[id].minimum = -1;
    nodes[id].maximum = 0;
    nodes[id].summary = -1;
    if (universe > 2) {
        std::uint32_t exponent = 0;
        for (auto value = universe; value > 1; value >>= 1) ++exponent;
        const auto low_bits = exponent / 2;
        const auto low_size = 1U << low_bits;
        const auto cluster_count = universe / low_size;
        nodes[id].low_bits = static_cast<std::uint8_t>(low_bits);
        nodes[id].cluster_count = static_cast<std::uint8_t>(cluster_count);
        nodes[id].summary = initialize(nodes, next, cluster_count);
        for (std::uint32_t i = 0; i < cluster_count; ++i)
            nodes[id].clusters[i] = initialize(nodes, next, low_size);
    }
    return id;
}

bool contains(const VebNode *nodes, std::int32_t id, std::uint32_t value)
{
    const auto &node = nodes[id];
    if (node.minimum < 0) return false;
    if (static_cast<std::uint32_t>(node.minimum) == value ||
        static_cast<std::uint32_t>(node.maximum) == value) return true;
    if (node.universe == 2) return false;
    const auto low_size = 1U << node.low_bits;
    const auto high = value >> node.low_bits;
    const auto low = value & (low_size - 1U);
    return contains(nodes, node.clusters[high], low);
}

void insert(VebNode *nodes, std::int32_t id, std::uint32_t value)
{
    auto &node = nodes[id];
    if (contains(nodes, id, value)) return;
    if (node.minimum < 0) {
        node.minimum = node.maximum = static_cast<std::int32_t>(value);
        return;
    }
    if (value < static_cast<std::uint32_t>(node.minimum)) {
        const auto old_minimum = static_cast<std::uint32_t>(node.minimum);
        node.minimum = static_cast<std::int32_t>(value);
        value = old_minimum;
    }
    if (node.universe > 2) {
        const auto low_size = 1U << node.low_bits;
        const auto high = value >> node.low_bits;
        const auto low = value & (low_size - 1U);
        const auto cluster_id = node.clusters[high];
        if (nodes[cluster_id].minimum < 0) {
            insert(nodes, node.summary, high);
            nodes[cluster_id].minimum = nodes[cluster_id].maximum = static_cast<std::int32_t>(low);
        } else {
            insert(nodes, cluster_id, low);
        }
    }
    if (value > static_cast<std::uint32_t>(node.maximum)) node.maximum = static_cast<std::int32_t>(value);
}

std::int32_t successor(const VebNode *nodes, std::int32_t id, std::uint32_t value)
{
    const auto &node = nodes[id];
    if (node.minimum < 0) return -1;
    if (value < static_cast<std::uint32_t>(node.minimum)) return node.minimum;
    if (node.universe == 2) return value == 0 && node.maximum == 1 ? 1 : -1;
    const auto low_size = 1U << node.low_bits;
    const auto high = value >> node.low_bits;
    const auto low = value & (low_size - 1U);
    const auto cluster_id = node.clusters[high];
    if (nodes[cluster_id].minimum >= 0 && low < static_cast<std::uint32_t>(nodes[cluster_id].maximum)) {
        const auto next_low = successor(nodes, cluster_id, low);
        if (next_low < 0) return -1;
        return static_cast<std::int32_t>(high * low_size) + next_low;
    }
    const auto next_cluster = successor(nodes, node.summary, high);
    if (next_cluster < 0) return -1;
    const auto next_minimum = nodes[node.clusters[static_cast<std::uint32_t>(next_cluster)]].minimum;
    if (next_minimum < 0) return -1;
    return next_cluster * static_cast<std::int32_t>(low_size) + next_minimum;
}

std::int32_t predecessor(const VebNode *nodes, std::int32_t id, std::uint32_t value)
{
    const auto &node = nodes[id];
    if (node.minimum < 0 || value <= static_cast<std::uint32_t>(node.minimum)) return -1;
    if (value > static_cast<std::uint32_t>(node.maximum)) return node.maximum;
    if (node.universe == 2) return value == 1 && node.minimum == 0 ? 0 : -1;
    const auto low_size = 1U << node.low_bits;
    const auto high = value >> node.low_bits;
    const auto low = value & (low_size - 1U);
    const auto cluster_id = node.clusters[high];
    if (nodes[cluster_id].minimum >= 0 && low > static_cast<std::uint32_t>(nodes[cluster_id].minimum)) {
        const auto previous_low = predecessor(nodes, cluster_id, low);
        if (previous_low >= 0) return static_cast<std::int32_t>(high * low_size) + previous_low;
    }
    const auto previous_cluster = predecessor(nodes, node.summary, high);
    if (previous_cluster < 0) return node.minimum;
    const auto previous_maximum = nodes[node.clusters[static_cast<std::uint32_t>(previous_cluster)]].maximum;
    if (previous_maximum < 0) return -1;
    return previous_cluster * static_cast<std::int32_t>(low_size) + previous_maximum;
}
}

extern "C" std::int64_t veb_tree(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 3 || length > MAX_INPUT_VALUES + 1) return -1;
    if (input[0] < 2 || input[0] > 256 || input[1] < 0 || input[1] > 256 ||
        input[2] < 0 || input[2] > 256) return -1;
    const auto requested_universe = static_cast<std::uint32_t>(input[0]);
    const auto insert_count = static_cast<std::size_t>(input[1]);
    const auto query_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + insert_count + 2 * query_count) return -1;
    for (std::size_t i = 0; i < insert_count; ++i)
        if (input[3 + i] < 0 || input[3 + i] >= requested_universe) return -1;
    for (std::size_t i = 0; i < query_count; ++i) {
        const auto opcode = input[3 + insert_count + 2 * i];
        const auto key = input[4 + insert_count + 2 * i];
        if (opcode < 0 || opcode > 4 || key < 0 || key >= requested_universe) return -1;
    }
    const auto needed = query_count * 4;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == nullptr || capacity < needed) return -2;

    std::uint32_t rounded_universe = 1;
    while (rounded_universe < requested_universe) rounded_universe <<= 1;
    VebNode nodes[MAX_TREE_NODES]{};
    std::size_t next_node = 0;
    const auto root = initialize(nodes, next_node, rounded_universe);
    for (std::size_t i = 0; i < insert_count; ++i)
        insert(nodes, root, static_cast<std::uint32_t>(input[3 + i]));

    std::uint8_t result[MAX_OUTPUT_BYTES];
    for (std::size_t i = 0; i < query_count; ++i) {
        const auto opcode = static_cast<std::int32_t>(input[3 + insert_count + 2 * i]);
        const auto key = static_cast<std::uint32_t>(input[4 + insert_count + 2 * i]);
        std::int32_t value;
        if (opcode == 0) value = contains(nodes, root, key) ? 1 : 0;
        else if (opcode == 1) value = successor(nodes, root, key);
        else if (opcode == 2) value = predecessor(nodes, root, key);
        else if (opcode == 3) value = nodes[root].minimum;
        else value = nodes[root].minimum < 0 ? 0 : nodes[root].maximum;
        const auto bits = static_cast<std::uint32_t>(value);
        result[4 * i] = static_cast<std::uint8_t>(bits);
        result[4 * i + 1] = static_cast<std::uint8_t>(bits >> 8);
        result[4 * i + 2] = static_cast<std::uint8_t>(bits >> 16);
        result[4 * i + 3] = static_cast<std::uint8_t>(bits >> 24);
    }
    for (std::size_t i = 0; i < needed; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(needed);
}
