#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxItems = 5;
constexpr int kMaxAtoms = 3;
constexpr std::size_t kMaxInput = 43;
constexpr int kMaxOutputWords = 9;

struct Instance {
    std::int64_t reward[kMaxItems]{};
    int atom_count[kMaxItems]{};
    std::int64_t denominator[kMaxItems]{};
    std::int64_t fit_weight[kMaxItems]{};
    std::int64_t truncated_size_weight[kMaxItems]{};
    int size[kMaxItems][kMaxAtoms]{};
    int weight[kMaxItems][kMaxAtoms]{};
};

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

bool density_before(const Instance &in, int left, int right)
{
    const auto left_score = in.reward[left] * in.fit_weight[left] * in.truncated_size_weight[right];
    const auto right_score = in.reward[right] * in.fit_weight[right] * in.truncated_size_weight[left];
    return left_score != right_score ? left_score > right_score : left < right;
}
}

extern "C" std::int64_t stochastic_knapsack_greedy(const std::int64_t *input,
                                                     std::size_t length,
                                                     std::uint8_t *output,
                                                     std::size_t capacity)
{
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n_raw = input[0], bound_raw = input[1];
    if (n_raw < 1 || n_raw > kMaxItems || bound_raw < 1 || bound_raw > 8) return -1;
    const int n = static_cast<int>(n_raw), bound = static_cast<int>(bound_raw);
    Instance in{};
    std::size_t position = 2;
    for (int item = 0; item < n; ++item) {
        if (position + 2 > length) return -1;
        const auto reward = input[position++];
        const auto atom_count_raw = input[position++];
        if (reward < 0 || reward > 20 || atom_count_raw < 1 || atom_count_raw > kMaxAtoms) return -1;
        in.reward[item] = reward;
        in.atom_count[item] = static_cast<int>(atom_count_raw);
        for (int atom = 0; atom < in.atom_count[item]; ++atom) {
            if (position + 2 > length) return -1;
            const auto size = input[position++], weight = input[position++];
            if (size < 0 || size > bound + 1 || weight < 1 || weight > 3) return -1;
            in.size[item][atom] = static_cast<int>(size);
            in.weight[item][atom] = static_cast<int>(weight);
            in.denominator[item] += weight;
            if (size <= bound) in.fit_weight[item] += weight;
            in.truncated_size_weight[item] += (size < bound ? size : bound) * weight;
        }
        if (in.denominator[item] > 9 || in.truncated_size_weight[item] == 0) return -1;
    }
    if (position != length) return -1;

    int order[kMaxItems];
    for (int i = 0; i < n; ++i) {
        int j = i;
        while (j > 0 && density_before(in, i, order[j - 1])) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = i;
    }
    int best_single = 0;
    for (int i = 1; i < n; ++i) {
        const auto left = in.reward[i] * in.fit_weight[i] * in.denominator[best_single];
        const auto right = in.reward[best_single] * in.fit_weight[best_single] * in.denominator[i];
        if (left > right) best_single = i;
    }

    std::int64_t joint_denominator = 1;
    int scenario_count = 1;
    for (int i = 0; i < n; ++i) {
        joint_denominator *= in.denominator[i];
        scenario_count *= in.atom_count[i];
    }
    std::int64_t singleton_score = 0, order_score = 0;
    int selected_size[kMaxItems];
    for (int scenario = 0; scenario < scenario_count; ++scenario) {
        int digits = scenario;
        std::int64_t scenario_weight = 1;
        for (int item = 0; item < n; ++item) {
            const int atom = digits % in.atom_count[item];
            digits /= in.atom_count[item];
            selected_size[item] = in.size[item][atom];
            scenario_weight *= in.weight[item][atom];
        }
        if (selected_size[best_single] <= bound) singleton_score += scenario_weight * in.reward[best_single];
        int used = 0;
        std::int64_t reward = 0;
        for (int rank = 0; rank < n; ++rank) {
            const int item = order[rank];
            if (used + selected_size[item] > bound) break;
            used += selected_size[item];
            reward += in.reward[item];
        }
        order_score += scenario_weight * reward;
    }

    const bool use_order = order_score > singleton_score;
    std::int64_t staged[kMaxOutputWords]{};
    staged[0] = use_order ? 1 : 0;
    const int output_count = use_order ? n : 1;
    staged[1] = output_count;
    for (int i = 0; i < output_count; ++i) staged[2 + i] = use_order ? order[i] : best_single;
    staged[2 + output_count] = use_order ? order_score : singleton_score;
    staged[3 + output_count] = joint_denominator;
    const auto words = static_cast<std::size_t>(output_count + 4);
    const auto bytes = words * 8;
    if (output == nullptr || capacity < bytes) return -2;
    for (std::size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return static_cast<std::int64_t>(bytes);
}
