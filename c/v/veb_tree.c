/* Bounded Van Emde Boas set adapted from TheAlgorithms/Rust. */
#include <stddef.h>
#include <stdint.h>

#define MAX_UNIVERSE 256
#define MAX_COUNT 256
#define MAX_INPUT_VALUES 771
#define MAX_OUTPUT_BYTES 1024
#define MAX_TREE_NODES 358
#define MAX_CLUSTERS 16

typedef struct {
    uint16_t universe;
    uint8_t low_bits;
    uint8_t cluster_count;
    int32_t minimum;
    int32_t maximum;
    int32_t summary;
    int32_t clusters[MAX_CLUSTERS];
} VebNode;

static int32_t initialize(VebNode *nodes, size_t *next, uint32_t universe)
{
    const int32_t id = (int32_t)(*next);
    ++*next;
    nodes[id].universe = (uint16_t)universe;
    nodes[id].low_bits = 0;
    nodes[id].cluster_count = 0;
    nodes[id].minimum = -1;
    nodes[id].maximum = 0;
    nodes[id].summary = -1;
    if (universe > 2) {
        uint32_t exponent = 0;
        for (uint32_t value = universe; value > 1; value >>= 1) ++exponent;
        const uint32_t low_bits = exponent / 2;
        const uint32_t low_size = 1U << low_bits;
        const uint32_t cluster_count = universe / low_size;
        nodes[id].low_bits = (uint8_t)low_bits;
        nodes[id].cluster_count = (uint8_t)cluster_count;
        nodes[id].summary = initialize(nodes, next, cluster_count);
        for (uint32_t i = 0; i < cluster_count; ++i)
            nodes[id].clusters[i] = initialize(nodes, next, low_size);
    }
    return id;
}

static int contains(const VebNode *nodes, int32_t id, uint32_t value)
{
    const VebNode *node = &nodes[id];
    if (node->minimum < 0) return 0;
    if ((uint32_t)node->minimum == value || (uint32_t)node->maximum == value) return 1;
    if (node->universe == 2) return 0;
    const uint32_t low_size = 1U << node->low_bits;
    const uint32_t high = value >> node->low_bits;
    const uint32_t low = value & (low_size - 1U);
    return contains(nodes, node->clusters[high], low);
}

static void insert(VebNode *nodes, int32_t id, uint32_t value)
{
    VebNode *node = &nodes[id];
    if (contains(nodes, id, value)) return;
    if (node->minimum < 0) {
        node->minimum = (int32_t)value;
        node->maximum = (int32_t)value;
        return;
    }
    if (value < (uint32_t)node->minimum) {
        const uint32_t old_minimum = (uint32_t)node->minimum;
        node->minimum = (int32_t)value;
        value = old_minimum;
    }
    if (node->universe > 2) {
        const uint32_t low_size = 1U << node->low_bits;
        const uint32_t high = value >> node->low_bits;
        const uint32_t low = value & (low_size - 1U);
        const int32_t cluster_id = node->clusters[high];
        if (nodes[cluster_id].minimum < 0) {
            insert(nodes, node->summary, high);
            nodes[cluster_id].minimum = (int32_t)low;
            nodes[cluster_id].maximum = (int32_t)low;
        } else {
            insert(nodes, cluster_id, low);
        }
    }
    if (value > (uint32_t)node->maximum) node->maximum = (int32_t)value;
}

static int32_t successor(const VebNode *nodes, int32_t id, uint32_t value)
{
    const VebNode *node = &nodes[id];
    if (node->minimum < 0) return -1;
    if (value < (uint32_t)node->minimum) return node->minimum;
    if (node->universe == 2)
        return value == 0 && node->maximum == 1 ? 1 : -1;
    const uint32_t low_size = 1U << node->low_bits;
    const uint32_t high = value >> node->low_bits;
    const uint32_t low = value & (low_size - 1U);
    const int32_t cluster_id = node->clusters[high];
    if (nodes[cluster_id].maximum >= 0 && low < (uint32_t)nodes[cluster_id].maximum) {
        const int32_t next_low = successor(nodes, cluster_id, low);
        if (next_low < 0) return -1;
        return (int32_t)(high * low_size) + next_low;
    }
    const int32_t next_cluster = successor(nodes, node->summary, high);
    if (next_cluster < 0) return -1;
    const int32_t next_minimum = nodes[node->clusters[(uint32_t)next_cluster]].minimum;
    if (next_minimum < 0) return -1;
    return next_cluster * (int32_t)low_size + next_minimum;
}

static int32_t predecessor(const VebNode *nodes, int32_t id, uint32_t value)
{
    const VebNode *node = &nodes[id];
    if (node->minimum < 0 || value <= (uint32_t)node->minimum) return -1;
    if (value > (uint32_t)node->maximum) return node->maximum;
    if (node->universe == 2)
        return value == 1 && node->minimum == 0 ? 0 : -1;
    const uint32_t low_size = 1U << node->low_bits;
    const uint32_t high = value >> node->low_bits;
    const uint32_t low = value & (low_size - 1U);
    const int32_t cluster_id = node->clusters[high];
    if (nodes[cluster_id].minimum >= 0 && low > (uint32_t)nodes[cluster_id].minimum) {
        const int32_t previous_low = predecessor(nodes, cluster_id, low);
        if (previous_low >= 0) return (int32_t)(high * low_size) + previous_low;
    }
    const int32_t previous_cluster = predecessor(nodes, node->summary, high);
    if (previous_cluster < 0) return node->minimum;
    const int32_t previous_maximum = nodes[node->clusters[(uint32_t)previous_cluster]].maximum;
    if (previous_maximum < 0) return -1;
    return previous_cluster * (int32_t)low_size + previous_maximum;
}

int64_t veb_tree(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 3 || length > MAX_INPUT_VALUES + 1) return -1;
    if (input[0] < 2 || input[0] > MAX_UNIVERSE) return -1;
    if (input[1] < 0 || input[1] > MAX_COUNT || input[2] < 0 || input[2] > MAX_COUNT) return -1;
    const uint32_t requested_universe = (uint32_t)input[0];
    const size_t insert_count = (size_t)input[1];
    const size_t query_count = (size_t)input[2];
    if (length != 3 + insert_count + 2 * query_count) return -1;
    for (size_t i = 0; i < insert_count; ++i)
        if (input[3 + i] < 0 || input[3 + i] >= (int64_t)requested_universe) return -1;
    for (size_t i = 0; i < query_count; ++i) {
        const int64_t opcode = input[3 + insert_count + 2 * i];
        const int64_t key = input[4 + insert_count + 2 * i];
        if (opcode < 0 || opcode > 4 || key < 0 || key >= (int64_t)requested_universe) return -1;
    }

    const size_t needed = query_count * 4;
    if (needed > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < needed) return -2;

    uint32_t rounded_universe = 1;
    while (rounded_universe < requested_universe) rounded_universe <<= 1;
    VebNode nodes[MAX_TREE_NODES];
    size_t next_node = 0;
    const int32_t root = initialize(nodes, &next_node, rounded_universe);
    for (size_t i = 0; i < insert_count; ++i)
        insert(nodes, root, (uint32_t)input[3 + i]);

    uint8_t result[MAX_OUTPUT_BYTES];
    for (size_t i = 0; i < query_count; ++i) {
        const int32_t opcode = (int32_t)input[3 + insert_count + 2 * i];
        const uint32_t key = (uint32_t)input[4 + insert_count + 2 * i];
        int32_t value;
        if (opcode == 0) value = contains(nodes, root, key);
        else if (opcode == 1) value = successor(nodes, root, key);
        else if (opcode == 2) value = predecessor(nodes, root, key);
        else if (opcode == 3) value = nodes[root].minimum;
        else value = nodes[root].minimum < 0 ? 0 : nodes[root].maximum;
        const uint32_t bits = (uint32_t)value;
        result[4 * i] = (uint8_t)bits;
        result[4 * i + 1] = (uint8_t)(bits >> 8);
        result[4 * i + 2] = (uint8_t)(bits >> 16);
        result[4 * i + 3] = (uint8_t)(bits >> 24);
    }
    for (size_t i = 0; i < needed; ++i) output[i] = result[i];
    return (int64_t)needed;
}
