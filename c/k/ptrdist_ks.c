#include <stddef.h>
#include <stdint.h>

#define MAX_MODULES 8
#define MAX_NETS 16
#define MAX_MEMBERS MAX_MODULES
#define MAX_INPUT 146

static int edge_cut(const int *side, const int nets[MAX_NETS][MAX_MEMBERS],
                    const int *degrees, int net_count) {
    int total = 0;
    for (int net = 0; net < net_count; ++net) {
        for (int i = 0; i < degrees[net]; ++i) {
            for (int j = i + 1; j < degrees[net]; ++j) {
                if (side[nets[net][i]] != side[nets[net][j]]) ++total;
            }
        }
    }
    return total;
}

static int net_cut(const int *side, const int nets[MAX_NETS][MAX_MEMBERS],
                   const int *degrees, int net_count) {
    int total = 0;
    for (int net = 0; net < net_count; ++net) {
        int first = side[nets[net][0]];
        for (int i = 1; i < degrees[net]; ++i) {
            if (side[nets[net][i]] != first) {
                ++total;
                break;
            }
        }
    }
    return total;
}

int64_t ptrdist_ks(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int modules = (int)input[0];
    const int net_count = (int)input[1];
    if (input[0] < 2 || input[0] > MAX_MODULES || (modules & 1) != 0 ||
        input[1] < 0 || input[1] > MAX_NETS) return -1;

    int nets[MAX_NETS][MAX_MEMBERS] = {{0}};
    int degrees[MAX_NETS] = {0};
    size_t cursor = 2;
    for (int net = 0; net < net_count; ++net) {
        if (cursor >= length) return -1;
        const int64_t degree_value = input[cursor++];
        if (degree_value < 2 || degree_value > modules ||
            cursor + (size_t)degree_value > length) return -1;
        const int degree = (int)degree_value;
        degrees[net] = degree;
        for (int i = 0; i < degree; ++i) {
            const int64_t member_value = input[cursor++];
            if (member_value < 0 || member_value >= modules) return -1;
            for (int j = 0; j < i; ++j) {
                if (nets[net][j] == (int)member_value) return -1;
            }
            nets[net][i] = (int)member_value;
        }
    }
    if (cursor != length) return -1;

    const int half = modules / 2;
    int order_a[MAX_MODULES], order_b[MAX_MODULES];
    int side[MAX_MODULES];
    for (int i = 0; i < half; ++i) {
        order_a[i] = i;
        order_b[i] = half + i;
        side[i] = 0;
        side[half + i] = 1;
    }
    int accepted_passes = 0;

    for (;;) {
        int work[MAX_MODULES];
        int remaining_a[MAX_MODULES], remaining_b[MAX_MODULES];
        int selected_a[MAX_MODULES], selected_b[MAX_MODULES];
        int count_a = half, count_b = half;
        for (int i = 0; i < modules; ++i) work[i] = side[i];
        for (int i = 0; i < half; ++i) {
            remaining_a[i] = order_a[i];
            remaining_b[i] = order_b[i];
        }
        int cumulative_gain = 0;
        int best_gain = INT32_MIN;
        int best_prefix = 0;

        for (int step = 0; step < half; ++step) {
            const int baseline = edge_cut(work, nets, degrees, net_count);
            int pair_gain = INT32_MIN;
            int chosen_a = -1, chosen_b = -1;
            for (int ai = 0; ai < count_a; ++ai) {
                const int a = remaining_a[ai];
                for (int bi = 0; bi < count_b; ++bi) {
                    const int b = remaining_b[bi];
                    work[a] = 1;
                    work[b] = 0;
                    const int gain = baseline - edge_cut(work, nets, degrees, net_count);
                    work[a] = 0;
                    work[b] = 1;
                    if (gain > pair_gain) {
                        pair_gain = gain;
                        chosen_a = a;
                        chosen_b = b;
                    }
                }
            }

            selected_a[step] = chosen_a;
            selected_b[step] = chosen_b;
            work[chosen_a] = 1;
            work[chosen_b] = 0;
            for (int i = 0; i < count_a; ++i) {
                if (remaining_a[i] == chosen_a) {
                    for (int j = i; j + 1 < count_a; ++j) remaining_a[j] = remaining_a[j + 1];
                    --count_a;
                    break;
                }
            }
            for (int i = 0; i < count_b; ++i) {
                if (remaining_b[i] == chosen_b) {
                    for (int j = i; j + 1 < count_b; ++j) remaining_b[j] = remaining_b[j + 1];
                    --count_b;
                    break;
                }
            }
            cumulative_gain += pair_gain;
            if (cumulative_gain > best_gain) {
                best_gain = cumulative_gain;
                best_prefix = step + 1;
            }
        }

        if (best_gain <= 0) break;
        int next_a[MAX_MODULES], next_b[MAX_MODULES];
        int out = 0;
        for (int i = 0; i < best_prefix; ++i) next_a[out++] = selected_b[i];
        for (int i = best_prefix; i < half; ++i) next_a[out++] = selected_a[i];
        out = 0;
        for (int i = 0; i < best_prefix; ++i) next_b[out++] = selected_a[i];
        for (int i = best_prefix; i < half; ++i) next_b[out++] = selected_b[i];
        for (int i = 0; i < half; ++i) {
            order_a[i] = next_a[i];
            order_b[i] = next_b[i];
        }
        for (int i = 0; i < half; ++i) {
            side[order_a[i]] = 0;
            side[order_b[i]] = 1;
        }
        ++accepted_passes;
    }

    int mask = 0;
    for (int i = 0; i < modules; ++i) if (side[i] == 0) mask |= 1 << i;
    const int edges = edge_cut(side, nets, degrees, net_count);
    const int cut_nets = net_cut(side, nets, degrees, net_count);
    return (int64_t)mask + ((int64_t)edges << 8) +
           ((int64_t)cut_nets << 17) + ((int64_t)accepted_passes << 22);
}
