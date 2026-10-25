#include <cstdint>

namespace {
constexpr std::int32_t min_size = 2;
constexpr std::int32_t max_size = 1024;
constexpr std::int32_t max_nodes = max_size - 1;
constexpr std::int32_t modulus = 10000;
constexpr std::int32_t multiplier = 31415821;
constexpr std::int32_t value_range = 100;

struct Node { std::int32_t value; std::int32_t left; std::int32_t right; };

std::int32_t multiply(std::int32_t p, std::int32_t q) {
    const auto p_high = p / modulus;
    const auto p_low = p % modulus;
    const auto q_high = q / modulus;
    const auto q_low = q % modulus;
    return ((p_low * q_high + p_high * q_low) % modulus) * modulus +
           p_low * q_low;
}

std::int32_t next_random(std::int32_t seed) { return multiply(seed, multiplier) + 1; }

std::int32_t skip_random(std::int32_t seed, std::int32_t count) {
    for (std::int32_t i = 0; i < count; ++i) seed = next_random(seed);
    return seed;
}

std::int32_t make_tree(Node *nodes, std::int32_t &used,
                       std::int32_t size, std::int32_t seed) {
    if (size <= 1) return -1;
    seed = next_random(seed);
    const std::int32_t index = used++;
    nodes[index].value = seed % value_range;
    const std::int32_t half = size / 2;
    nodes[index].left = make_tree(nodes, used, half, seed);
    nodes[index].right = make_tree(nodes, used, half, skip_random(seed, size + 1));
    return index;
}

void swap_left(Node *nodes, std::int32_t left, std::int32_t right,
               std::int32_t left_left, std::int32_t right_left,
               std::int32_t left_value, std::int32_t right_value) {
    nodes[right].value = left_value;
    nodes[right].left = left_left;
    nodes[left].left = right_left;
    nodes[left].value = right_value;
}

void swap_right(Node *nodes, std::int32_t left, std::int32_t right,
                std::int32_t left_right, std::int32_t right_right,
                std::int32_t left_value, std::int32_t right_value) {
    nodes[right].value = left_value;
    nodes[right].right = left_right;
    nodes[left].right = right_right;
    nodes[left].value = right_value;
}

std::int32_t merge(Node *nodes, std::int32_t root,
                   std::int32_t spill, std::int32_t direction) {
    std::int32_t root_value = nodes[root].value;
    std::int32_t left = nodes[root].left;
    std::int32_t right = nodes[root].right;
    const std::int32_t right_exchange = (root_value > spill) ^ direction;
    if (right_exchange) {
        nodes[root].value = spill;
        spill = root_value;
    }
    while (left >= 0) {
        const std::int32_t left_value = nodes[left].value;
        const std::int32_t left_left = nodes[left].left;
        const std::int32_t left_right = nodes[left].right;
        const std::int32_t right_value = nodes[right].value;
        const std::int32_t right_left = nodes[right].left;
        const std::int32_t right_right = nodes[right].right;
        const std::int32_t element_exchange = (left_value > right_value) ^ direction;
        if (right_exchange) {
            if (element_exchange) {
                swap_right(nodes, left, right, left_right, right_right,
                           left_value, right_value);
                left = left_left;
                right = right_left;
            } else {
                left = left_right;
                right = right_right;
            }
        } else if (element_exchange) {
            swap_left(nodes, left, right, left_left, right_left,
                      left_value, right_value);
            left = left_right;
            right = right_right;
        } else {
            left = left_left;
            right = right_left;
        }
    }
    if (nodes[root].left >= 0) {
        const std::int32_t left_root = nodes[root].left;
        const std::int32_t right_root = nodes[root].right;
        root_value = nodes[root].value;
        nodes[root].value = merge(nodes, left_root, root_value, direction);
        spill = merge(nodes, right_root, spill, direction);
    }
    return spill;
}

std::int32_t sort_tree(Node *nodes, std::int32_t root,
                       std::int32_t spill, std::int32_t direction) {
    if (nodes[root].left < 0) {
        if ((nodes[root].value > spill) ^ direction) {
            const std::int32_t value = nodes[root].value;
            nodes[root].value = spill;
            spill = value;
        }
        return spill;
    }
    const std::int32_t left = nodes[root].left;
    const std::int32_t right = nodes[root].right;
    const std::int32_t value = nodes[root].value;
    nodes[root].value = sort_tree(nodes, left, value, direction);
    spill = sort_tree(nodes, right, spill, !direction);
    return merge(nodes, root, spill, direction);
}

void checksum(const Node *nodes, std::int32_t index,
              std::int64_t &position, std::int64_t &sum) {
    if (index < 0) return;
    checksum(nodes, nodes[index].left, position, sum);
    ++position;
    sum += position * nodes[index].value;
    checksum(nodes, nodes[index].right, position, sum);
}
}

extern "C" std::int64_t bisort(std::int64_t size) {
    if (size < min_size || size > max_size) return -1;
    Node nodes[max_nodes];
    std::int32_t used = 0;
    const std::int32_t root = make_tree(nodes, used, static_cast<std::int32_t>(size), 12345768);
    std::int32_t spill = next_random(245867) % value_range;
    spill = sort_tree(nodes, root, spill, 0);
    spill = sort_tree(nodes, root, spill, 1);
    std::int64_t position = 0;
    std::int64_t sum = 0;
    checksum(nodes, root, position, sum);
    ++position;
    return sum + position * spill;
}
