/* Clean-room port of SIM's documented first-best local affine score. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE 64
#define STRIDE 65
#define CELLS (STRIDE * STRIDE)

int64_t ptrdist_sim_local_affine_alignment(const int64_t *input, size_t length)
{
    if (input == NULL || length < 4 || length > 2 + 2 * MAX_SEQUENCE) return -1;
    if (input[0] < 1 || input[0] > MAX_SEQUENCE) return -1;
    size_t left = (size_t)input[0];
    size_t right_len_pos = 1 + left;
    if (right_len_pos >= length || input[right_len_pos] < 1 || input[right_len_pos] > MAX_SEQUENCE) return -1;
    size_t right = (size_t)input[right_len_pos];
    if (length != right_len_pos + 1 + right) return -1;
    for (size_t i = 0; i < left; ++i) {
        int64_t c = input[1 + i];
        if (c != 65 && c != 67 && c != 71 && c != 84) return -1;
    }
    for (size_t j = 0; j < right; ++j) {
        int64_t c = input[right_len_pos + 1 + j];
        if (c != 65 && c != 67 && c != 71 && c != 84) return -1;
    }
    int64_t h[CELLS] = {0}, deletion[CELLS] = {0}, insertion[CELLS] = {0};
    for (size_t j = 1; j <= right; ++j) deletion[j] = -60;
    for (size_t i = 1; i <= left; ++i) insertion[i * STRIDE] = -60;
    int64_t best = 0;
    for (size_t i = 1; i <= left; ++i) {
        for (size_t j = 1; j <= right; ++j) {
            size_t at = i * STRIDE + j;
            int64_t d_open = h[at - STRIDE] - 62;
            int64_t d_extend = deletion[at - STRIDE] - 2;
            deletion[at] = d_open > d_extend ? d_open : d_extend;
            int64_t f_open = h[at - 1] - 62;
            int64_t f_extend = insertion[at - 1] - 2;
            insertion[at] = f_open > f_extend ? f_open : f_extend;
            int64_t a = input[1 + i - 1], b = input[right_len_pos + 1 + j - 1];
            int64_t score = h[at - STRIDE - 1] + (a == b ? 10 : -10);
            if (score < 0) score = 0;
            if (deletion[at] > score) score = deletion[at];
            if (insertion[at] > score) score = insertion[at];
            h[at] = score;
            if (score > best) best = score;
        }
    }
    return best;
}
