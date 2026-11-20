// Clean-room bounded Tunstall full-tree construction.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_s = INT64_C(4222124650659840);
constexpr std::int64_t result_factor = max_s + 1;
}

extern "C" std::int64_t tunstall_codebook_construction(const std::int64_t* input, std::size_t length) {
    if (!input || length < 4 || length > 7 || input[0] < 2 || input[0] > 4 || input[1] < 2 || input[1] > 4) return -1;
    const int k = static_cast<int>(input[0]);
    const int bits = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(k + 2)) return -1;
    std::array<std::int64_t, 4> weights{};
    std::int64_t total = 0;
    for (int i = 0; i < k; ++i) {
        const auto weight = input[2 + i];
        if (weight <= 0 || weight > 8) return -1;
        weights[i] = weight;
        total += weight;
    }
    if (total > 8) return -1;

    std::array<std::int64_t, 17> powers{};
    powers[0] = 1;
    for (int i = 1; i <= 16; ++i) powers[i] = powers[i - 1] * total;
    const int cap = 1 << bits;
    int target = cap;
    while ((target - 1) % (k - 1) != 0) --target;

    std::array<std::int64_t, 31> product{};
    std::array<int, 31> depth{};
    std::array<std::uint64_t, 31> phrase_key{};
    std::array<int, 16> leaves{};
    int node_count = 1;
    int leaf_count = 0;
    for (int symbol = 0; symbol < k; ++symbol) {
        const int node = node_count++;
        product[node] = weights[symbol];
        depth[node] = 1;
        phrase_key[node] = static_cast<std::uint64_t>(symbol + 1) << 56;
        leaves[leaf_count++] = node;
    }

    std::int64_t scaled_expectation = powers[16];
    while (leaf_count < target) {
        int best_position = 0;
        int best_node = leaves[0];
        std::int64_t best_probability = product[best_node] * powers[15 - depth[best_node]];
        for (int position = 1; position < leaf_count; ++position) {
            const int candidate = leaves[position];
            const std::int64_t probability = product[candidate] * powers[15 - depth[candidate]];
            if (probability > best_probability ||
                (probability == best_probability && phrase_key[candidate] < phrase_key[best_node])) {
                best_position = position;
                best_node = candidate;
                best_probability = probability;
            }
        }

        scaled_expectation += product[best_node] * powers[16 - depth[best_node]];
        --leaf_count;
        leaves[best_position] = leaves[leaf_count];
        for (int symbol = 0; symbol < k; ++symbol) {
            const int child = node_count++;
            product[child] = product[best_node] * weights[symbol];
            depth[child] = depth[best_node] + 1;
            const int shift = 4 * (14 - depth[best_node]);
            phrase_key[child] = phrase_key[best_node] | (static_cast<std::uint64_t>(symbol + 1) << shift);
            leaves[leaf_count++] = child;
        }
    }
    const std::int64_t result = static_cast<std::int64_t>(target) * result_factor + scaled_expectation;
    return scaled_expectation <= max_s ? result : -1;
}
