#include <stdint.h>

#define BISORT_MIN_SIZE 2
#define BISORT_MAX_SIZE 1024
#define BISORT_MAX_NODES (BISORT_MAX_SIZE - 1)
#define BISORT_MODULUS 10000
#define BISORT_MULTIPLIER 31415821
#define BISORT_RANGE 100

typedef struct {
    int32_t value;
    int32_t left;
    int32_t right;
} bisort_node;

static int32_t bisort_multiply(int32_t p, int32_t q) {
    const int32_t p_high = p / BISORT_MODULUS;
    const int32_t p_low = p % BISORT_MODULUS;
    const int32_t q_high = q / BISORT_MODULUS;
    const int32_t q_low = q % BISORT_MODULUS;
    return ((p_low * q_high + p_high * q_low) % BISORT_MODULUS) *
               BISORT_MODULUS +
           p_low * q_low;
}

static int32_t bisort_random(int32_t seed) {
    return bisort_multiply(seed, BISORT_MULTIPLIER) + 1;
}

static int32_t bisort_skip_random(int32_t seed, int32_t count) {
    for (int32_t i = 0; i < count; ++i) seed = bisort_random(seed);
    return seed;
}

static int32_t bisort_make_tree(bisort_node *nodes, int32_t *used,
                                int32_t size, int32_t seed) {
    if (size <= 1) return -1;
    seed = bisort_random(seed);
    const int32_t index = (*used)++;
    nodes[index].value = seed % BISORT_RANGE;
    const int32_t half = size / 2;
    nodes[index].left = bisort_make_tree(nodes, used, half, seed);
    nodes[index].right = bisort_make_tree(
        nodes, used, half, bisort_skip_random(seed, size + 1));
    return index;
}

static void bisort_swap_left(bisort_node *nodes, int32_t left, int32_t right,
                             int32_t left_left, int32_t right_left,
                             int32_t left_value, int32_t right_value) {
    nodes[right].value = left_value;
    nodes[right].left = left_left;
    nodes[left].left = right_left;
    nodes[left].value = right_value;
}

static void bisort_swap_right(bisort_node *nodes, int32_t left, int32_t right,
                              int32_t left_right, int32_t right_right,
                              int32_t left_value, int32_t right_value) {
    nodes[right].value = left_value;
    nodes[right].right = left_right;
    nodes[left].right = right_right;
    nodes[left].value = right_value;
}

static int32_t bisort_merge(bisort_node *nodes, int32_t root,
                            int32_t spill, int32_t direction) {
    int32_t root_value = nodes[root].value;
    int32_t left = nodes[root].left;
    int32_t right = nodes[root].right;
    const int32_t right_exchange = (root_value > spill) ^ direction;
    if (right_exchange) {
        nodes[root].value = spill;
        spill = root_value;
    }

    while (left >= 0) {
        const int32_t left_value = nodes[left].value;
        const int32_t left_left = nodes[left].left;
        const int32_t left_right = nodes[left].right;
        const int32_t right_value = nodes[right].value;
        const int32_t right_left = nodes[right].left;
        const int32_t right_right = nodes[right].right;
        const int32_t element_exchange = (left_value > right_value) ^ direction;
        if (right_exchange) {
            if (element_exchange) {
                bisort_swap_right(nodes, left, right, left_right, right_right,
                                  left_value, right_value);
                left = left_left;
                right = right_left;
            } else {
                left = left_right;
                right = right_right;
            }
        } else if (element_exchange) {
            bisort_swap_left(nodes, left, right, left_left, right_left,
                             left_value, right_value);
            left = left_right;
            right = right_right;
        } else {
            left = left_left;
            right = right_left;
        }
    }

    if (nodes[root].left >= 0) {
        const int32_t left_root = nodes[root].left;
        const int32_t right_root = nodes[root].right;
        root_value = nodes[root].value;
        nodes[root].value = bisort_merge(nodes, left_root, root_value, direction);
        spill = bisort_merge(nodes, right_root, spill, direction);
    }
    return spill;
}

static int32_t bisort_tree(bisort_node *nodes, int32_t root,
                           int32_t spill, int32_t direction) {
    if (nodes[root].left < 0) {
        if ((nodes[root].value > spill) ^ direction) {
            const int32_t value = nodes[root].value;
            nodes[root].value = spill;
            spill = value;
        }
        return spill;
    }
    const int32_t left = nodes[root].left;
    const int32_t right = nodes[root].right;
    const int32_t value = nodes[root].value;
    nodes[root].value = bisort_tree(nodes, left, value, direction);
    spill = bisort_tree(nodes, right, spill, !direction);
    return bisort_merge(nodes, root, spill, direction);
}

static void bisort_checksum(const bisort_node *nodes, int32_t index,
                            int64_t *position, int64_t *sum) {
    if (index < 0) return;
    bisort_checksum(nodes, nodes[index].left, position, sum);
    ++*position;
    *sum += *position * nodes[index].value;
    bisort_checksum(nodes, nodes[index].right, position, sum);
}

int64_t bisort(int64_t size) {
    if (size < BISORT_MIN_SIZE || size > BISORT_MAX_SIZE) return -1;
    bisort_node nodes[BISORT_MAX_NODES];
    int32_t used = 0;
    const int32_t root = bisort_make_tree(nodes, &used, (int32_t)size, 12345768);
    int32_t spill = bisort_random(245867) % BISORT_RANGE;
    spill = bisort_tree(nodes, root, spill, 0);
    spill = bisort_tree(nodes, root, spill, 1);
    int64_t position = 0;
    int64_t checksum = 0;
    bisort_checksum(nodes, root, &position, &checksum);
    ++position;
    return checksum + position * spill;
}
