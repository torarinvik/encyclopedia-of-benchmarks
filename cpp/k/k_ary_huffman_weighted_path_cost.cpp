#include <cstddef>
#include <cstdint>

extern "C" std::int64_t k_ary_huffman_weighted_path_cost(
    const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 3 || length > 13) return -1;
    const auto arity_value = input[0];
    const auto count_value = input[1];
    if ((arity_value != 3 && arity_value != 4) || count_value < 1 || count_value > 10) return -1;
    const auto arity = static_cast<std::size_t>(arity_value);
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 2 || (count > 1 && (count - 1) % (arity - 1) != 0)) return -1;

    std::int64_t weights[16]{};
    bool active[16]{};
    for (std::size_t index = 0; index < count; ++index) {
        const auto weight = input[index + 2];
        if (weight < 0 || weight > 1000) return -1;
        weights[index] = weight;
        active[index] = true;
    }

    std::size_t node_count = count;
    std::size_t active_count = count;
    std::int64_t cost = 0;
    while (active_count > 1) {
        std::int64_t combined = 0;
        for (std::size_t pick = 0; pick < arity; ++pick) {
            std::size_t best = 16;
            for (std::size_t index = 0; index < node_count; ++index) {
                if (!active[index]) continue;
                if (best == 16) best = index;
                else if (weights[index] < weights[best]
                         || (weights[index] == weights[best] && index < best)) best = index;
            }
            if (best == 16) return -1;
            combined += weights[best];
            active[best] = false;
            --active_count;
        }
        cost += combined;
        weights[node_count] = combined;
        active[node_count] = true;
        ++node_count;
        ++active_count;
    }
    return cost;
}
