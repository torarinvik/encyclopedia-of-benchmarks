#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define NN_LINES 16
#define NN_WORDS 4
#define NN_SIDE 8
#define NN_MAX_OUTPUT 64

typedef struct { uint64_t word[NN_LINES][NN_WORDS]; } nn_domains;

static bool nn_matches(uint32_t mask, size_t length, const int64_t *clue, size_t count) {
    size_t found = 0, run = 0;
    for (size_t bit = 0; bit < length; ++bit) {
        if ((mask >> bit) & 1u) ++run;
        else if (run != 0) {
            if (found >= count || clue[found] != (int64_t)run) return false;
            ++found; run = 0;
        }
    }
    if (run != 0) {
        if (found >= count || clue[found] != (int64_t)run) return false;
        ++found;
    }
    return found == count;
}

static bool nn_has(const nn_domains *domains, size_t line, uint32_t mask) {
    return (domains->word[line][mask >> 6] & (UINT64_C(1) << (mask & 63))) != 0;
}

static void nn_add(nn_domains *domains, size_t line, uint32_t mask) {
    domains->word[line][mask >> 6] |= UINT64_C(1) << (mask & 63);
}

static size_t nn_count(const nn_domains *domains, size_t line, size_t length) {
    size_t count = 0;
    for (uint32_t mask = 0; mask < (UINT32_C(1) << length); ++mask)
        count += nn_has(domains, line, mask);
    return count;
}

static bool nn_filter(nn_domains *domains, size_t line, size_t length, size_t position,
                      bool allow_zero, bool allow_one) {
    bool changed = false;
    for (uint32_t mask = 0; mask < (UINT32_C(1) << length); ++mask) {
        if (!nn_has(domains, line, mask)) continue;
        const bool one = ((mask >> position) & 1u) != 0;
        if (one ? allow_one : allow_zero) continue;
        domains->word[line][mask >> 6] &= ~(UINT64_C(1) << (mask & 63));
        changed = true;
    }
    return changed;
}

static bool nn_support(const nn_domains *domains, size_t line, size_t length,
                       size_t position, bool *zero, bool *one) {
    *zero = false; *one = false;
    for (uint32_t mask = 0; mask < (UINT32_C(1) << length); ++mask) {
        if (!nn_has(domains, line, mask)) continue;
        if ((mask >> position) & 1u) *one = true;
        else *zero = true;
    }
    return *zero || *one;
}

static bool nn_propagate(nn_domains *domains, size_t height, size_t width) {
    bool changed;
    do {
        changed = false;
        for (size_t row = 0; row < height; ++row) {
            for (size_t col = 0; col < width; ++col) {
                bool rz, ro, cz, co;
                if (!nn_support(domains, row, width, col, &rz, &ro) ||
                    !nn_support(domains, height + col, height, row, &cz, &co)) return false;
                changed |= nn_filter(domains, row, width, col, cz, co);
                changed |= nn_filter(domains, height + col, height, row, rz, ro);
                if (nn_count(domains, row, width) == 0 ||
                    nn_count(domains, height + col, height) == 0) return false;
            }
        }
    } while (changed);
    return true;
}

static bool nn_search(nn_domains *domains, size_t height, size_t width) {
    if (!nn_propagate(domains, height, width)) return false;
    size_t branch = height;
    for (size_t row = 0; row < height; ++row) {
        if (nn_count(domains, row, width) > 1) { branch = row; break; }
    }
    if (branch == height) return true;
    for (uint32_t mask = 0; mask < (UINT32_C(1) << width); ++mask) {
        if (!nn_has(domains, branch, mask)) continue;
        nn_domains trial = *domains;
        memset(trial.word[branch], 0, sizeof(trial.word[branch]));
        nn_add(&trial, branch, mask);
        if (nn_search(&trial, height, width)) { *domains = trial; return true; }
    }
    return false;
}

static bool nn_parse(const int64_t *input, size_t length, size_t *height, size_t *width,
                     int64_t clues[NN_LINES][NN_SIDE], size_t counts[NN_LINES]) {
    if (input == NULL || length < 2 || input[0] < 1 || input[0] > NN_SIDE ||
        input[1] < 1 || input[1] > NN_SIDE) return false;
    *height = (size_t)input[0]; *width = (size_t)input[1];
    if (length != 2 + 5 * *height + 5 * *width) return false;
    memset(clues, 0, sizeof(int64_t) * NN_LINES * NN_SIDE);
    memset(counts, 0, sizeof(size_t) * NN_LINES);
    size_t offset = 2;
    for (size_t group = 0; group < 2; ++group) {
        const size_t lines = group == 0 ? *height : *width;
        const size_t line_length = group == 0 ? *width : *height;
        for (size_t line = 0; line < lines; ++line) {
            const size_t index = group == 0 ? line : *height + line;
            const int64_t count = input[offset++];
            if (count < 0 || count > 4) return false;
            counts[index] = (size_t)count;
            int64_t needed = count == 0 ? 0 : count - 1;
            for (size_t run = 0; run < 4; ++run) {
                const int64_t value = input[offset++];
                if (run < counts[index]) {
                    if (value <= 0 || value > (int64_t)line_length) return false;
                    clues[index][run] = value;
                    needed += value;
                } else if (value != 0) return false;
            }
            if (needed > (int64_t)line_length) return false;
        }
    }
    int64_t row_total = 0, col_total = 0;
    for (size_t row = 0; row < *height; ++row)
        for (size_t run = 0; run < counts[row]; ++run) row_total += clues[row][run];
    for (size_t col = 0; col < *width; ++col)
        for (size_t run = 0; run < counts[*height + col]; ++run) col_total += clues[*height + col][run];
    return row_total == col_total;
}

int64_t nonogram_line_domain_solver(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    size_t height = 0, width = 0;
    int64_t clues[NN_LINES][NN_SIDE];
    size_t counts[NN_LINES];
    if (!nn_parse(input, length, &height, &width, clues, counts)) return -1;
    nn_domains domains = {0};
    for (size_t row = 0; row < height; ++row)
        for (uint32_t mask = 0; mask < (UINT32_C(1) << width); ++mask)
            if (nn_matches(mask, width, clues[row], counts[row])) nn_add(&domains, row, mask);
    for (size_t col = 0; col < width; ++col)
        for (uint32_t mask = 0; mask < (UINT32_C(1) << height); ++mask)
            if (nn_matches(mask, height, clues[height + col], counts[height + col]))
                nn_add(&domains, height + col, mask);
    for (size_t row = 0; row < height; ++row)
        if (nn_count(&domains, row, width) == 0) return -1;
    for (size_t col = 0; col < width; ++col)
        if (nn_count(&domains, height + col, height) == 0) return -1;
    if (!nn_search(&domains, height, width)) return -1;
    const size_t required = height * width;
    if (output == NULL || capacity < required) return -2;
    for (size_t row = 0; row < height; ++row) {
        uint32_t mask = 0;
        while (mask < (UINT32_C(1) << width) && !nn_has(&domains, row, mask)) ++mask;
        for (size_t col = 0; col < width; ++col)
            output[row * width + col] = (uint8_t)((mask >> col) & 1u);
    }
    return (int64_t)required;
}
