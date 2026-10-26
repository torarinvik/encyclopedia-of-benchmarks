#include <stddef.h>
#include <stdint.h>

#define MAX_ITEMS 5
#define MAX_ATOMS 3
#define MAX_INPUT 43
#define MAX_OUTPUT_WORDS 9

typedef struct {
    int64_t reward[MAX_ITEMS];
    int atom_count[MAX_ITEMS];
    int64_t denominator[MAX_ITEMS];
    int64_t fit_weight[MAX_ITEMS];
    int64_t truncated_size_weight[MAX_ITEMS];
    int size[MAX_ITEMS][MAX_ATOMS];
    int weight[MAX_ITEMS][MAX_ATOMS];
} Instance;

static void store_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

static int density_before(const Instance *in, int left, int right)
{
    const int64_t left_score = in->reward[left] * in->fit_weight[left]
        * in->truncated_size_weight[right];
    const int64_t right_score = in->reward[right] * in->fit_weight[right]
        * in->truncated_size_weight[left];
    return left_score != right_score ? left_score > right_score : left < right;
}

int64_t stochastic_knapsack_greedy(const int64_t *input, size_t length,
                                   uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n_raw = input[0], bound_raw = input[1];
    if (n_raw < 1 || n_raw > MAX_ITEMS || bound_raw < 1 || bound_raw > 8) return -1;
    const int n = (int)n_raw, bound = (int)bound_raw;
    Instance in = {0};
    size_t position = 2;
    for (int item = 0; item < n; ++item) {
        if (position + 2 > length) return -1;
        const int64_t reward = input[position++];
        const int64_t atom_count_raw = input[position++];
        if (reward < 0 || reward > 20 || atom_count_raw < 1 || atom_count_raw > MAX_ATOMS) return -1;
        in.reward[item] = reward;
        in.atom_count[item] = (int)atom_count_raw;
        for (int atom = 0; atom < in.atom_count[item]; ++atom) {
            if (position + 2 > length) return -1;
            const int64_t size = input[position++], weight = input[position++];
            if (size < 0 || size > bound + 1 || weight < 1 || weight > 3) return -1;
            in.size[item][atom] = (int)size;
            in.weight[item][atom] = (int)weight;
            in.denominator[item] += weight;
            if (size <= bound) in.fit_weight[item] += weight;
            in.truncated_size_weight[item] += (size < bound ? size : bound) * weight;
        }
        if (in.denominator[item] > 9 || in.truncated_size_weight[item] == 0) return -1;
    }
    if (position != length) return -1;

    int order[MAX_ITEMS];
    for (int i = 0; i < n; ++i) {
        int j = i;
        while (j > 0 && density_before(&in, i, order[j - 1])) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = i;
    }
    int best_single = 0;
    for (int i = 1; i < n; ++i) {
        const int64_t left = in.reward[i] * in.fit_weight[i] * in.denominator[best_single];
        const int64_t right = in.reward[best_single] * in.fit_weight[best_single] * in.denominator[i];
        if (left > right) best_single = i;
    }

    int64_t joint_denominator = 1;
    int scenario_count = 1;
    for (int i = 0; i < n; ++i) {
        joint_denominator *= in.denominator[i];
        scenario_count *= in.atom_count[i];
    }
    int64_t singleton_score = 0, order_score = 0;
    int selected_size[MAX_ITEMS];
    for (int scenario = 0; scenario < scenario_count; ++scenario) {
        int digits = scenario;
        int64_t scenario_weight = 1;
        for (int item = 0; item < n; ++item) {
            const int atom = digits % in.atom_count[item];
            digits /= in.atom_count[item];
            selected_size[item] = in.size[item][atom];
            scenario_weight *= in.weight[item][atom];
        }
        if (selected_size[best_single] <= bound)
            singleton_score += scenario_weight * in.reward[best_single];
        int used = 0;
        int64_t reward = 0;
        for (int rank = 0; rank < n; ++rank) {
            const int item = order[rank];
            if (used + selected_size[item] > bound) break;
            used += selected_size[item];
            reward += in.reward[item];
        }
        order_score += scenario_weight * reward;
    }

    const int use_order = order_score > singleton_score;
    int64_t staged[MAX_OUTPUT_WORDS] = {0};
    staged[0] = use_order ? 1 : 0;
    const int output_count = use_order ? n : 1;
    staged[1] = output_count;
    for (int i = 0; i < output_count; ++i) staged[2 + i] = use_order ? order[i] : best_single;
    staged[2 + output_count] = use_order ? order_score : singleton_score;
    staged[3 + output_count] = joint_denominator;
    const size_t words = (size_t)output_count + 4;
    const size_t bytes = words * 8;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t word = 0; word < words; ++word) store_i64_le(output, word * 8, staged[word]);
    return (int64_t)bytes;
}
