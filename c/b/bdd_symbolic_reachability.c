#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum {
    MAX_INPUT = 133,
    MAX_NODES = 17000,
    UNIQUE_CAP = 32768,
};

typedef struct {
    uint8_t variable[MAX_NODES];
    uint16_t low[MAX_NODES];
    uint16_t high[MAX_NODES];
    uint16_t unique[UNIQUE_CAP];
    uint16_t exists_result[MAX_NODES];
    uint16_t rename_result[MAX_NODES];
    uint16_t next_id;
    uint8_t variable_count;
    bool failed;
} BddManager;

static uint32_t unique_hash(uint32_t variable, uint32_t low, uint32_t high) {
    return (variable * 4099u + low * 131u + high) & (UNIQUE_CAP - 1u);
}

static uint16_t make_node(BddManager *manager, uint8_t variable,
                          uint16_t low, uint16_t high) {
    if (low == high) return low;
    uint32_t slot = unique_hash(variable, low, high);
    for (uint32_t probes = 0; probes < UNIQUE_CAP; ++probes) {
        uint16_t encoded = manager->unique[slot];
        if (encoded == 0) {
            if (manager->next_id >= MAX_NODES) {
                manager->failed = true;
                return 0;
            }
            uint16_t id = manager->next_id++;
            manager->variable[id] = variable;
            manager->low[id] = low;
            manager->high[id] = high;
            manager->unique[slot] = (uint16_t)(id + 1u);
            return id;
        }
        uint16_t id = (uint16_t)(encoded - 1u);
        if (manager->variable[id] == variable && manager->low[id] == low &&
            manager->high[id] == high) {
            return id;
        }
        slot = (slot + 1u) & (UNIQUE_CAP - 1u);
    }
    manager->failed = true;
    return 0;
}

static void reset_round(BddManager *manager, uint16_t relation_end) {
    memset(manager->unique, 0, sizeof(manager->unique));
    memset(manager->exists_result, 0, sizeof(manager->exists_result));
    memset(manager->rename_result, 0, sizeof(manager->rename_result));
    manager->next_id = relation_end;
    for (uint32_t id = 2; id < relation_end; ++id) {
        uint32_t slot = unique_hash(manager->variable[id], manager->low[id],
                                    manager->high[id]);
        while (manager->unique[slot] != 0)
            slot = (slot + 1u) & (UNIQUE_CAP - 1u);
        manager->unique[slot] = (uint16_t)(id + 1u);
    }
}

static uint8_t top_variable(const BddManager *manager, uint16_t node) {
    return node < 2 ? manager->variable_count : manager->variable[node];
}

static void children_at(const BddManager *manager, uint16_t node,
                        uint8_t variable, uint16_t *low, uint16_t *high) {
    if (node >= 2 && manager->variable[node] == variable) {
        *low = manager->low[node];
        *high = manager->high[node];
    } else {
        *low = node;
        *high = node;
    }
}

static uint16_t apply_recursive(BddManager *manager, uint16_t left,
                                uint16_t right, bool is_or) {
    if (manager->failed) return 0;
    if (is_or) {
        if (left == 1 || right == 1) return 1;
        if (left == 0) return right;
        if (right == 0 || left == right) return left;
    } else {
        if (left == 0 || right == 0) return 0;
        if (left == 1) return right;
        if (right == 1 || left == right) return left;
    }
    if (left > right) {
        uint16_t swap = left;
        left = right;
        right = swap;
    }

    uint8_t variable = top_variable(manager, left);
    uint8_t right_variable = top_variable(manager, right);
    if (right_variable < variable) variable = right_variable;
    uint16_t left_low, left_high, right_low, right_high;
    children_at(manager, left, variable, &left_low, &left_high);
    children_at(manager, right, variable, &right_low, &right_high);
    uint16_t result_low = apply_recursive(manager, left_low, right_low, is_or);
    uint16_t result_high = apply_recursive(manager, left_high, right_high, is_or);
    uint16_t result = make_node(manager, variable, result_low, result_high);
    if (manager->failed) return 0;
    return result;
}

static uint16_t apply_binary(BddManager *manager, uint16_t left,
                             uint16_t right, bool is_or) {
    return apply_recursive(manager, left, right, is_or);
}

static uint16_t truth_table_recursive(BddManager *manager, const int64_t *bits,
                                      uint8_t variable, size_t prefix,
                                      uint8_t variable_count) {
    if (manager->failed) return 0;
    if (variable == variable_count) return (uint16_t)bits[prefix];
    uint16_t low = truth_table_recursive(manager, bits, (uint8_t)(variable + 1u),
                                         prefix * 2u, variable_count);
    uint16_t high = truth_table_recursive(manager, bits, (uint8_t)(variable + 1u),
                                          prefix * 2u + 1u, variable_count);
    return make_node(manager, variable, low, high);
}

static uint16_t exists_recursive(BddManager *manager, uint16_t node,
                                 uint8_t quantified_variables) {
    if (manager->failed || node < 2) return node;
    uint16_t cached = manager->exists_result[node];
    if (cached != 0) return (uint16_t)(cached - 1u);
    uint8_t variable = manager->variable[node];
    uint16_t low = exists_recursive(manager, manager->low[node], quantified_variables);
    uint16_t high = exists_recursive(manager, manager->high[node], quantified_variables);
    uint16_t result = variable < quantified_variables
        ? apply_binary(manager, low, high, true)
        : make_node(manager, variable, low, high);
    if (!manager->failed) manager->exists_result[node] = (uint16_t)(result + 1u);
    return result;
}

static uint16_t rename_recursive(BddManager *manager, uint16_t node,
                                 uint8_t first_variable) {
    if (manager->failed || node < 2) return node;
    uint16_t cached = manager->rename_result[node];
    if (cached != 0) return (uint16_t)(cached - 1u);
    uint8_t variable = manager->variable[node];
    if (variable < first_variable) {
        manager->failed = true;
        return 0;
    }
    uint16_t low = rename_recursive(manager, manager->low[node], first_variable);
    uint16_t high = rename_recursive(manager, manager->high[node], first_variable);
    uint16_t result = make_node(manager, (uint8_t)(variable - first_variable), low, high);
    if (!manager->failed) manager->rename_result[node] = (uint16_t)(result + 1u);
    return result;
}

static uint8_t evaluate(const BddManager *manager, uint16_t node,
                        uint16_t assignment, uint8_t variable_count) {
    while (node >= 2) {
        uint8_t variable = manager->variable[node];
        uint8_t shift = (uint8_t)(variable_count - variable - 1u);
        node = ((assignment >> shift) & 1u) ? manager->high[node] : manager->low[node];
    }
    return (uint8_t)node;
}

int64_t bdd_symbolic_reachability(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t n_raw = input[0], m_raw = input[1];
    int64_t initial_raw = input[2], invariant_raw = input[3];
    if (n_raw < 1 || n_raw > 3 || m_raw < 0 || m_raw > 1) return -1;
    uint8_t n = (uint8_t)n_raw, m = (uint8_t)m_raw;
    uint16_t state_count = (uint16_t)(1u << n);
    uint16_t state_mask = (uint16_t)((1u << state_count) - 1u);
    size_t relation_length = (size_t)1u << (2u * n + m);
    if (initial_raw < 0 || invariant_raw < 0 ||
        ((uint64_t)initial_raw & ~(uint64_t)state_mask) != 0 ||
        ((uint64_t)invariant_raw & ~(uint64_t)state_mask) != 0 ||
        length != 4u + relation_length) return -1;
    for (size_t i = 0; i < relation_length; ++i)
        if (input[4u + i] != 0 && input[4u + i] != 1) return -1;

    BddManager manager = {0};
    manager.next_id = 2;
    manager.variable_count = (uint8_t)(2u * n + m);

    uint16_t relation = truth_table_recursive(&manager, input + 4, 0, 0,
                                                manager.variable_count);
    if (manager.failed) return -1;
    const uint16_t relation_end = manager.next_id;

    uint16_t reached_mask = (uint16_t)initial_raw;
    uint16_t reached_node = 0;
    for (uint16_t iteration = 0; iteration <= state_count; ++iteration) {
        reset_round(&manager, relation_end);
        int64_t reached_bits[8] = {0};
        for (uint16_t state = 0; state < state_count; ++state)
            reached_bits[state] = (reached_mask >> state) & 1u;
        reached_node = truth_table_recursive(&manager, reached_bits, 0, 0, n);
        uint16_t product = apply_binary(&manager, reached_node, relation, false);
        uint16_t next_set = exists_recursive(&manager, product, (uint8_t)(n + m));
        next_set = rename_recursive(&manager, next_set, (uint8_t)(n + m));
        uint16_t joined = apply_binary(&manager, reached_node, next_set, true);
        if (manager.failed) return -1;
        if (joined == reached_node) break;
        reached_mask = 0;
        for (uint16_t state = 0; state < state_count; ++state)
            reached_mask |= (uint16_t)(evaluate(&manager, joined, state, n) << state);
        if (iteration == state_count) return -1;
    }
    uint16_t violation = (reached_mask & (uint16_t)~(uint16_t)invariant_raw) != 0;
    return ((int64_t)reached_mask << 1) | violation;
}
