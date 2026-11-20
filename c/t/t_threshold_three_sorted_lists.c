#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { TT_LISTS = 3, TT_MAX_LIST = 32, TT_MAX_VALUES = 48,
       TT_MAX_INPUT = 3 + TT_LISTS * TT_MAX_LIST };
enum { TT_WHITE = 0, TT_GREEN = 1, TT_RED = 2 };

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t t_threshold_three_sorted_lists(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 6 || length > TT_MAX_INPUT + 1) return -1;
    size_t base[TT_LISTS], size[TT_LISTS], at = 0;
    for (size_t list = 0; list < TT_LISTS; ++list) {
        if (at >= length || input[at] < 1 || input[at] > TT_MAX_LIST) return -1;
        size[list] = (size_t)input[at++];
        if (size[list] > length - at) return -1;
        base[list] = at;
        for (size_t j = 0; j < size[list]; ++j) {
            int64_t value = input[at + j];
            if (value < INT32_MIN || value > INT32_MAX ||
                (j > 0 && input[at + j - 1] >= value)) return -1;
        }
        at += size[list];
    }
    if (at != length) return -1;

    int64_t tails[TT_LISTS];
    for (size_t i = 0; i < TT_LISTS; ++i) tails[i] = input[base[i] + size[i] - 1];
    for (size_t i = 0; i < TT_LISTS; ++i)
        for (size_t j = i + 1; j < TT_LISTS; ++j)
            if (tails[i] > tails[j]) { int64_t t = tails[i]; tails[i] = tails[j]; tails[j] = t; }
    const int64_t maximum_candidate = tails[1];

    int64_t firsts[TT_LISTS];
    for (size_t i = 0; i < TT_LISTS; ++i) firsts[i] = input[base[i]];
    for (size_t i = 0; i < TT_LISTS; ++i)
        for (size_t j = i + 1; j < TT_LISTS; ++j)
            if (firsts[i] > firsts[j]) { int64_t t = firsts[i]; firsts[i] = firsts[j]; firsts[j] = t; }
    int64_t candidate = firsts[1];

    uint8_t color[TT_LISTS] = {TT_WHITE, TT_WHITE, TT_WHITE};
    size_t cursor[TT_LISTS] = {1, 1, 1};
    size_t search_base[TT_LISTS] = {1, 1, 1};
    size_t search_low[TT_LISTS] = {1, 1, 1};
    size_t search_step[TT_LISTS] = {1, 1, 1};
    size_t search_probe[TT_LISTS] = {1, 1, 1};
    size_t representative[TT_LISTS] = {0, 0, 0};
    bool representative_present[TT_LISTS] = {false, false, false};
    for (size_t i = 0; i < TT_LISTS; ++i) {
        if (input[base[i]] == candidate) color[i] = TT_GREEN;
        if (input[base[i]] > candidate) {
            color[i] = TT_RED;
            representative[i] = 0;
            representative_present[i] = true;
        }
    }

    int64_t result[TT_MAX_VALUES];
    size_t result_count = 0;
    size_t round_robin = 0;
    while (candidate <= maximum_candidate) {
        size_t green_count = 0, red_count = 0, white_count = 0;
        for (size_t i = 0; i < TT_LISTS; ++i) {
            if (color[i] == TT_GREEN) ++green_count;
            else if (color[i] == TT_RED) ++red_count;
            else ++white_count;
        }

        if (green_count >= 2 || red_count >= 2) {
            if (green_count >= 2) result[result_count++] = candidate;
            size_t recolor_count = white_count < 1 ? 1 - white_count : 0;
            for (size_t i = 0; i < TT_LISTS && recolor_count > 0; ++i) {
                if (color[i] != TT_GREEN) continue;
                color[i] = TT_WHITE;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
                --recolor_count;
            }
            for (size_t i = 0; i < TT_LISTS; ++i) {
                if (color[i] != TT_GREEN) continue;
                color[i] = TT_RED;
                representative[i] = cursor[i];
                representative_present[i] = cursor[i] < size[i];
            }

            bool found = false;
            int64_t next_candidate = INT64_MAX;
            for (size_t i = 0; i < TT_LISTS; ++i) {
                if (!representative_present[i]) continue;
                int64_t value = input[base[i] + representative[i]];
                if (!found || value < next_candidate) { found = true; next_candidate = value; }
            }
            if (!found) break;
            candidate = next_candidate;
            for (size_t i = 0; i < TT_LISTS; ++i) {
                if (color[i] != TT_RED || !representative_present[i] ||
                    input[base[i] + representative[i]] != candidate) continue;
                color[i] = TT_GREEN;
                representative_present[i] = false;
                cursor[i] = representative[i] + 1;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
            }
            continue;
        }

        size_t list_id = TT_LISTS;
        for (size_t offset = 0; offset < TT_LISTS; ++offset) {
            size_t i = (round_robin + offset) % TT_LISTS;
            if (color[i] == TT_WHITE) { list_id = i; break; }
        }
        if (list_id == TT_LISTS) break;
        round_robin = (list_id + 1) % TT_LISTS;
        size_t probe = search_probe[list_id];
        if (probe >= size[list_id]) probe = size[list_id] - 1;
        int64_t observed = input[base[list_id] + probe];
        if (observed < candidate) {
            search_low[list_id] = probe + 1;
            if (probe == size[list_id] - 1) {
                color[list_id] = TT_RED;
                representative[list_id] = size[list_id];
                representative_present[list_id] = false;
            } else {
                search_step[list_id] *= 2;
                size_t next_probe = search_base[list_id] + search_step[list_id] - 1;
                search_probe[list_id] = next_probe < size[list_id] ? next_probe : size[list_id] - 1;
            }
            continue;
        }

        size_t low = search_low[list_id], high = probe + 1;
        while (low < high) {
            size_t middle = low + (high - low) / 2;
            if (input[base[list_id] + middle] < candidate) low = middle + 1;
            else high = middle;
        }
        if (low < size[list_id] && input[base[list_id] + low] == candidate) {
            color[list_id] = TT_GREEN;
            cursor[list_id] = low + 1;
        } else {
            color[list_id] = TT_RED;
            representative[list_id] = low;
            representative_present[list_id] = low < size[list_id];
        }
    }

    size_t output_bytes = 8 * (1 + result_count);
    if (output == NULL || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (int64_t)result_count);
    for (size_t i = 0; i < result_count; ++i) put_i64_le(output, 8 * (i + 1), result[i]);
    return (int64_t)output_bytes;
}
