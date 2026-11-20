#include <stddef.h>
#include <stdint.h>

#define FDM_MAX_TEXT 4096
#define FDM_MAX_PATTERN 128
#define FDM_MAX_INPUT (2 + FDM_MAX_TEXT + FDM_MAX_PATTERN + 1)
#define FDM_MAX_STATES (2 * FDM_MAX_PATTERN + 2)
#define FDM_ALPHABET 4

typedef struct {
    int64_t transition[FDM_MAX_STATES][FDM_ALPHABET];
    int64_t suffix_link[FDM_MAX_STATES];
    int64_t max_length[FDM_MAX_STATES];
    size_t state_count;
} fdm_sam;

static void fdm_init(fdm_sam *sam) {
    sam->state_count = 1;
    for (size_t state = 0; state < FDM_MAX_STATES; ++state) {
        sam->suffix_link[state] = -1;
        sam->max_length[state] = 0;
        for (size_t symbol = 0; symbol < FDM_ALPHABET; ++symbol)
            sam->transition[state][symbol] = -1;
    }
}

static int64_t fdm_extend(fdm_sam *sam, int64_t last, size_t symbol) {
    if (sam->state_count >= FDM_MAX_STATES) return -1;
    const size_t current = sam->state_count++;
    sam->max_length[current] = sam->max_length[(size_t)last] + 1;
    int64_t state = last;
    while (state >= 0 && sam->transition[(size_t)state][symbol] < 0) {
        sam->transition[(size_t)state][symbol] = (int64_t)current;
        state = sam->suffix_link[(size_t)state];
    }
    if (state < 0) {
        sam->suffix_link[current] = 0;
    } else {
        const int64_t target = sam->transition[(size_t)state][symbol];
        if (sam->max_length[(size_t)state] + 1 == sam->max_length[(size_t)target]) {
            sam->suffix_link[current] = target;
        } else {
            if (sam->state_count >= FDM_MAX_STATES) return -1;
            const size_t clone = sam->state_count++;
            sam->max_length[clone] = sam->max_length[(size_t)state] + 1;
            sam->suffix_link[clone] = sam->suffix_link[(size_t)target];
            for (size_t c = 0; c < FDM_ALPHABET; ++c)
                sam->transition[clone][c] = sam->transition[(size_t)target][c];
            while (state >= 0 && sam->transition[(size_t)state][symbol] == target) {
                sam->transition[(size_t)state][symbol] = (int64_t)clone;
                state = sam->suffix_link[(size_t)state];
            }
            sam->suffix_link[(size_t)target] = (int64_t)clone;
            sam->suffix_link[current] = (int64_t)clone;
        }
    }
    return (int64_t)current;
}

static int64_t fdm_search(const fdm_sam *sam, const int64_t *text,
                          size_t n, size_t m) {
    size_t state = 0;
    int64_t matched_length = 0;
    int64_t matches = 0, offset_sum = 0, offset_xor = 0;
    for (size_t position = 0; position < n; ++position) {
        const size_t symbol = (size_t)text[position];
        int64_t target = sam->transition[state][symbol];
        if (target >= 0) {
            ++matched_length;
            state = (size_t)target;
        } else {
            while (state != 0 && sam->transition[state][symbol] < 0)
                state = (size_t)sam->suffix_link[state];
            target = sam->transition[state][symbol];
            if (target >= 0) {
                matched_length = sam->max_length[state] + 1;
                state = (size_t)target;
            } else {
                matched_length = 0;
                state = 0;
            }
        }
        if ((size_t)matched_length == m) {
            const int64_t start = (int64_t)(position + 1 - m);
            ++matches;
            offset_sum += start;
            offset_xor ^= start;
        }
    }
    return (matches << 36) | (offset_sum << 12) | offset_xor;
}

int64_t forward_dawg_matching(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > FDM_MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > FDM_MAX_TEXT ||
        m_value < 1 || m_value > FDM_MAX_PATTERN) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= FDM_ALPHABET) return -1;
    int64_t pattern[FDM_MAX_PATTERN];
    for (size_t i = 0; i < m; ++i) pattern[i] = input[2 + n + i];
    fdm_sam sam;
    fdm_init(&sam);
    int64_t last = 0;
    for (size_t i = 0; i < m; ++i) {
        last = fdm_extend(&sam, last, (size_t)pattern[i]);
        if (last < 0) return -1;
    }
    return fdm_search(&sam, input + 2, n, m);
}
