#include <stddef.h>
#include <stdint.h>

#define TRF_MAX_TEXT 4096
#define TRF_MAX_PATTERN 128
#define TRF_MAX_INPUT (2 + TRF_MAX_TEXT + TRF_MAX_PATTERN + 1)
#define TRF_MAX_STATES (2 * TRF_MAX_PATTERN + 2)
#define TRF_ALPHABET 4
#define TRF_ROOT 0
#define TRF_ARTIFICIAL 1

typedef struct {
    int64_t transition[TRF_MAX_STATES][TRF_ALPHABET];
    int64_t displacement[TRF_MAX_STATES][TRF_ALPHABET];
    int64_t suffix_link[TRF_MAX_STATES];
    int64_t max_length[TRF_MAX_STATES];
    int64_t position[TRF_MAX_STATES];
    int64_t terminal[TRF_MAX_STATES];
    size_t state_count;
} trf_automaton;

static void trf_init(trf_automaton *aut) {
    aut->state_count = 2;
    for (size_t state = 0; state < TRF_MAX_STATES; ++state) {
        aut->suffix_link[state] = -1;
        aut->max_length[state] = 0;
        aut->position[state] = 0;
        aut->terminal[state] = 0;
        for (size_t symbol = 0; symbol < TRF_ALPHABET; ++symbol) {
            aut->transition[state][symbol] = -1;
            aut->displacement[state][symbol] = 0;
        }
    }
    aut->suffix_link[TRF_ROOT] = TRF_ARTIFICIAL;
}

static int trf_build(trf_automaton *aut, const int64_t *pattern, size_t m) {
    size_t last = TRF_ROOT;
    for (size_t offset = 0; offset < m; ++offset) {
        const size_t symbol = (size_t)pattern[m - 1 - offset];
        if (aut->state_count >= TRF_MAX_STATES) return 0;
        const size_t current = aut->state_count++;
        aut->max_length[current] = aut->max_length[last] + 1;
        aut->position[current] = aut->position[last] + 1;
        int64_t state = (int64_t)last;
        while (state != TRF_ROOT && aut->transition[(size_t)state][symbol] < 0) {
            aut->transition[(size_t)state][symbol] = (int64_t)current;
            aut->displacement[(size_t)state][symbol] =
                aut->position[current] - aut->position[(size_t)state] - 1;
            state = aut->suffix_link[(size_t)state];
        }
        const int64_t target = aut->transition[(size_t)state][symbol];
        if (target < 0) {
            aut->transition[TRF_ROOT][symbol] = (int64_t)current;
            aut->displacement[TRF_ROOT][symbol] =
                aut->position[current] - aut->position[TRF_ROOT] - 1;
            aut->suffix_link[current] = TRF_ROOT;
        } else if (aut->max_length[(size_t)state] + 1 ==
                   aut->max_length[(size_t)target]) {
            aut->suffix_link[current] = target;
        } else {
            if (aut->state_count >= TRF_MAX_STATES) return 0;
            const size_t clone = aut->state_count++;
            aut->suffix_link[clone] = aut->suffix_link[(size_t)target];
            aut->max_length[clone] = aut->max_length[(size_t)state] + 1;
            aut->position[clone] = aut->position[(size_t)target];
            aut->terminal[clone] = aut->terminal[(size_t)target];
            for (size_t c = 0; c < TRF_ALPHABET; ++c) {
                aut->transition[clone][c] = aut->transition[(size_t)target][c];
                aut->displacement[clone][c] = aut->displacement[(size_t)target][c];
            }
            aut->suffix_link[(size_t)target] = (int64_t)clone;
            aut->suffix_link[current] = (int64_t)clone;
            while (state != TRF_ARTIFICIAL) {
                const int64_t old_target = aut->transition[(size_t)state][symbol];
                if (old_target < 0 ||
                    aut->max_length[(size_t)old_target] < aut->max_length[clone]) break;
                aut->displacement[(size_t)state][symbol] =
                    aut->position[(size_t)old_target] -
                    aut->position[(size_t)state] - 1;
                aut->transition[(size_t)state][symbol] = (int64_t)clone;
                state = aut->suffix_link[(size_t)state];
            }
        }
        last = current;
    }
    aut->terminal[last] = 1;
    while (last != TRF_ROOT) {
        last = (size_t)aut->suffix_link[last];
        aut->terminal[last] = 1;
    }
    return 1;
}

static void trf_mp_next(const int64_t *pattern, size_t m, int64_t *next) {
    int64_t i = 0, border = -1;
    next[0] = -1;
    while ((size_t)i < m) {
        while (border >= 0 && pattern[(size_t)i] != pattern[(size_t)border])
            border = next[(size_t)border];
        ++i;
        ++border;
        next[(size_t)i] = border;
    }
}

static int64_t trf_search(const trf_automaton *aut, const int64_t *text,
                          size_t n, size_t m, const int64_t *mp_next) {
    if (n < m) return 0;
    const int64_t period = (int64_t)m - mp_next[m];
    int64_t count = 0, offset_sum = 0, offset_xor = 0;
    size_t start = 0;
    int64_t preceding_shift = (int64_t)m;
    while (start <= n - m) {
        int64_t index = (int64_t)m - 1;
        size_t state = TRF_ROOT;
        int64_t boundary = (int64_t)m - 1 - preceding_shift;
        const int64_t prefix_length = (int64_t)m - preceding_shift;
        const int64_t period_of_prefix = preceding_shift != (int64_t)m
            ? prefix_length - mp_next[(size_t)prefix_length] : 0;
        int64_t shift = (int64_t)m;
        int64_t total_displacement = 0;
        while (index > boundary) {
            const size_t symbol = (size_t)text[start + (size_t)index];
            const int64_t target = aut->transition[state][symbol];
            if (target < 0) break;
            total_displacement += aut->displacement[state][symbol];
            state = (size_t)target;
            if (aut->terminal[state]) shift = index;
            --index;
        }
        if (index <= boundary) {
            if (total_displacement == 0) {
                ++count;
                offset_sum += (int64_t)start;
                offset_xor ^= (int64_t)start;
                shift = period;
            } else {
                const int64_t half = (boundary + 1) / 2;
                if (period_of_prefix <= half) {
                    boundary -= period_of_prefix;
                    while (index > boundary) {
                        const size_t symbol = (size_t)text[start + (size_t)index];
                        const int64_t target = aut->transition[state][symbol];
                        if (target < 0) break;
                        total_displacement += aut->displacement[state][symbol];
                        state = (size_t)target;
                        if (aut->terminal[state]) shift = index;
                        --index;
                    }
                    if (index <= boundary) shift = total_displacement;
                } else {
                    boundary = boundary - half - 1;
                    while (index > boundary) {
                        const size_t symbol = (size_t)text[start + (size_t)index];
                        const int64_t target = aut->transition[state][symbol];
                        if (target < 0) break;
                        total_displacement += aut->displacement[state][symbol];
                        state = (size_t)target;
                        if (aut->terminal[state]) shift = index;
                        --index;
                    }
                }
            }
        }
        if (shift <= 0) return -1;
        start += (size_t)shift;
        preceding_shift = shift;
    }
    return (count << 36) | (offset_sum << 12) | offset_xor;
}

int64_t turbo_reverse_factor_search(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > TRF_MAX_INPUT) return -1;
    const int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > TRF_MAX_TEXT ||
        m_value < 1 || m_value > TRF_MAX_PATTERN) return -1;
    const size_t n = (size_t)n_value, m = (size_t)m_value;
    if (length != 2 + n + m) return -1;
    for (size_t i = 0; i < n + m; ++i)
        if (input[2 + i] < 0 || input[2 + i] >= TRF_ALPHABET) return -1;
    int64_t pattern[TRF_MAX_PATTERN];
    int64_t mp_next[TRF_MAX_PATTERN + 1];
    for (size_t i = 0; i < m; ++i) pattern[i] = input[2 + n + i];
    trf_automaton aut;
    trf_init(&aut);
    if (!trf_build(&aut, pattern, m)) return -1;
    trf_mp_next(pattern, m, mp_next);
    return trf_search(&aut, input + 2, n, m, mp_next);
}
