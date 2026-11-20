#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT = 133;
constexpr std::size_t MAX_NODES = 17000;
constexpr std::size_t UNIQUE_CAP = 32768;

struct Manager {
    std::array<std::uint8_t, MAX_NODES> variable{};
    std::array<std::uint16_t, MAX_NODES> low{};
    std::array<std::uint16_t, MAX_NODES> high{};
    std::array<std::uint16_t, UNIQUE_CAP> unique{};
    std::array<std::uint16_t, MAX_NODES> exists_result{};
    std::array<std::uint16_t, MAX_NODES> rename_result{};
    std::uint16_t next_id = 2;
    std::uint8_t variable_count = 0;
    bool failed = false;
};

std::size_t unique_hash(std::uint32_t variable, std::uint32_t low,
                        std::uint32_t high) {
    return (variable * 4099u + low * 131u + high) & (UNIQUE_CAP - 1u);
}

std::uint16_t make_node(Manager &manager, std::uint8_t variable,
                        std::uint16_t low, std::uint16_t high) {
    if (low == high) return low;
    std::size_t slot = unique_hash(variable, low, high);
    for (std::size_t probes = 0; probes < UNIQUE_CAP; ++probes) {
        const auto encoded = manager.unique[slot];
        if (encoded == 0) {
            if (manager.next_id >= MAX_NODES) {
                manager.failed = true;
                return 0;
            }
            const auto id = manager.next_id++;
            manager.variable[id] = variable;
            manager.low[id] = low;
            manager.high[id] = high;
            manager.unique[slot] = static_cast<std::uint16_t>(id + 1u);
            return id;
        }
        const auto id = static_cast<std::uint16_t>(encoded - 1u);
        if (manager.variable[id] == variable && manager.low[id] == low &&
            manager.high[id] == high) return id;
        slot = (slot + 1u) & (UNIQUE_CAP - 1u);
    }
    manager.failed = true;
    return 0;
}

void reset_round(Manager &manager, std::uint16_t relation_end) {
    manager.unique.fill(0);
    manager.exists_result.fill(0);
    manager.rename_result.fill(0);
    manager.next_id = relation_end;
    for (std::uint32_t id = 2; id < relation_end; ++id) {
        auto slot = unique_hash(manager.variable[id], manager.low[id],
                                manager.high[id]);
        while (manager.unique[slot] != 0)
            slot = (slot + 1u) & (UNIQUE_CAP - 1u);
        manager.unique[slot] = static_cast<std::uint16_t>(id + 1u);
    }
}

std::uint8_t top_variable(const Manager &manager, std::uint16_t node) {
    return node < 2 ? manager.variable_count : manager.variable[node];
}

void children_at(const Manager &manager, std::uint16_t node,
                 std::uint8_t variable, std::uint16_t &low,
                 std::uint16_t &high) {
    if (node >= 2 && manager.variable[node] == variable) {
        low = manager.low[node];
        high = manager.high[node];
    } else {
        low = node;
        high = node;
    }
}

std::uint16_t apply_recursive(Manager &manager, std::uint16_t left,
                              std::uint16_t right, bool is_or) {
    if (manager.failed) return 0;
    if (is_or) {
        if (left == 1 || right == 1) return 1;
        if (left == 0) return right;
        if (right == 0 || left == right) return left;
    } else {
        if (left == 0 || right == 0) return 0;
        if (left == 1) return right;
        if (right == 1 || left == right) return left;
    }
    auto variable = top_variable(manager, left);
    const auto right_variable = top_variable(manager, right);
    if (right_variable < variable) variable = right_variable;
    std::uint16_t left_low, left_high, right_low, right_high;
    children_at(manager, left, variable, left_low, left_high);
    children_at(manager, right, variable, right_low, right_high);
    const auto result_low = apply_recursive(manager, left_low, right_low, is_or);
    const auto result_high = apply_recursive(manager, left_high, right_high, is_or);
    const auto result = make_node(manager, variable, result_low, result_high);
    if (manager.failed) return 0;
    return result;
}

std::uint16_t apply_binary(Manager &manager, std::uint16_t left,
                           std::uint16_t right, bool is_or) {
    return apply_recursive(manager, left, right, is_or);
}

std::uint16_t truth_table_recursive(Manager &manager, const std::int64_t *bits,
                                    std::uint8_t variable, std::size_t prefix,
                                    std::uint8_t variable_count) {
    if (manager.failed) return 0;
    if (variable == variable_count) return static_cast<std::uint16_t>(bits[prefix]);
    const auto low = truth_table_recursive(manager, bits,
        static_cast<std::uint8_t>(variable + 1u), prefix * 2u, variable_count);
    const auto high = truth_table_recursive(manager, bits,
        static_cast<std::uint8_t>(variable + 1u), prefix * 2u + 1u, variable_count);
    return make_node(manager, variable, low, high);
}

std::uint16_t exists_recursive(Manager &manager, std::uint16_t node,
                               std::uint8_t quantified_variables) {
    if (manager.failed || node < 2) return node;
    const auto cached = manager.exists_result[node];
    if (cached != 0) return static_cast<std::uint16_t>(cached - 1u);
    const auto variable = manager.variable[node];
    const auto low = exists_recursive(manager, manager.low[node], quantified_variables);
    const auto high = exists_recursive(manager, manager.high[node], quantified_variables);
    const auto result = variable < quantified_variables
        ? apply_binary(manager, low, high, true)
        : make_node(manager, variable, low, high);
    if (!manager.failed)
        manager.exists_result[node] = static_cast<std::uint16_t>(result + 1u);
    return result;
}

std::uint16_t rename_recursive(Manager &manager, std::uint16_t node,
                               std::uint8_t first_variable) {
    if (manager.failed || node < 2) return node;
    const auto cached = manager.rename_result[node];
    if (cached != 0) return static_cast<std::uint16_t>(cached - 1u);
    const auto variable = manager.variable[node];
    if (variable < first_variable) {
        manager.failed = true;
        return 0;
    }
    const auto low = rename_recursive(manager, manager.low[node], first_variable);
    const auto high = rename_recursive(manager, manager.high[node], first_variable);
    const auto result = make_node(manager,
        static_cast<std::uint8_t>(variable - first_variable), low, high);
    if (!manager.failed)
        manager.rename_result[node] = static_cast<std::uint16_t>(result + 1u);
    return result;
}

std::uint8_t evaluate(const Manager &manager, std::uint16_t node,
                     std::uint16_t assignment, std::uint8_t variable_count) {
    while (node >= 2) {
        const auto variable = manager.variable[node];
        const auto shift = static_cast<std::uint8_t>(variable_count - variable - 1u);
        node = ((assignment >> shift) & 1u) ? manager.high[node] : manager.low[node];
    }
    return static_cast<std::uint8_t>(node);
}
} // namespace

extern "C" std::int64_t bdd_symbolic_reachability(const std::int64_t *input,
                                                    std::size_t length) noexcept {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto n_raw = input[0], m_raw = input[1];
    const auto initial_raw = input[2], invariant_raw = input[3];
    if (n_raw < 1 || n_raw > 3 || m_raw < 0 || m_raw > 1) return -1;
    const auto n = static_cast<std::uint8_t>(n_raw);
    const auto m = static_cast<std::uint8_t>(m_raw);
    const auto state_count = static_cast<std::uint16_t>(1u << n);
    const auto state_mask = static_cast<std::uint16_t>((1u << state_count) - 1u);
    const auto relation_length = std::size_t{1} << (2u * n + m);
    if (initial_raw < 0 || invariant_raw < 0 ||
        (static_cast<std::uint64_t>(initial_raw) & ~static_cast<std::uint64_t>(state_mask)) != 0 ||
        (static_cast<std::uint64_t>(invariant_raw) & ~static_cast<std::uint64_t>(state_mask)) != 0 ||
        length != 4u + relation_length) return -1;
    for (std::size_t i = 0; i < relation_length; ++i)
        if (input[4u + i] != 0 && input[4u + i] != 1) return -1;

    Manager manager{};
    manager.variable_count = static_cast<std::uint8_t>(2u * n + m);
    const auto relation = truth_table_recursive(manager, input + 4, 0, 0,
                                                  manager.variable_count);
    if (manager.failed) return -1;
    const auto relation_end = manager.next_id;

    auto reached_mask = static_cast<std::uint16_t>(initial_raw);
    for (std::uint16_t iteration = 0; iteration <= state_count; ++iteration) {
        reset_round(manager, relation_end);
        std::array<std::int64_t, 8> reached_bits{};
        for (std::uint16_t state = 0; state < state_count; ++state)
            reached_bits[state] = (reached_mask >> state) & 1u;
        const auto reached = truth_table_recursive(manager, reached_bits.data(), 0, 0, n);
        const auto product = apply_binary(manager, reached, relation, false);
        auto next_set = exists_recursive(manager, product,
                                          static_cast<std::uint8_t>(n + m));
        next_set = rename_recursive(manager, next_set, static_cast<std::uint8_t>(n + m));
        const auto joined = apply_binary(manager, reached, next_set, true);
        if (manager.failed) return -1;
        if (joined == reached) break;
        reached_mask = 0;
        for (std::uint16_t state = 0; state < state_count; ++state)
            reached_mask |= static_cast<std::uint16_t>(evaluate(manager, joined, state, n) << state);
        if (iteration == state_count) return -1;
    }
    const auto violation = static_cast<std::uint16_t>(
        (reached_mask & static_cast<std::uint16_t>(~static_cast<std::uint16_t>(invariant_raw))) != 0);
    return (static_cast<std::int64_t>(reached_mask) << 1) | violation;
}
