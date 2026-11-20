module t_threshold_three_sorted_lists;

const usz LISTS = 3;
const usz MAX_LIST = 32;
const usz MAX_VALUES = 48;
const usz MAX_INPUT = 3 + LISTS * MAX_LIST;
const uint8 WHITE = 0;
const uint8 GREEN = 1;
const uint8 RED = 2;

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (uint8)(bits & 255);
        bits >>= 8;
    }
}

fn long t_threshold_three_sorted_lists(long* input, usz length,
        uint8* output, usz capacity)
        @export("t_threshold_three_sorted_lists") {
    if (input == null || length < 6 || length > MAX_INPUT + 1) return -1;
    usz[LISTS] base = zeroed;
    usz[LISTS] size = zeroed;
    usz at = 0;
    for (usz id = 0; id < LISTS; id += 1) {
        if (at >= length || input[at] < 1 || input[at] > (long)MAX_LIST) return -1;
        size[id] = (usz)input[at];
        at += 1;
        if (size[id] > length - at) return -1;
        base[id] = at;
        for (usz j = 0; j < size[id]; j += 1) {
            long value = input[at + j];
            if (value < -2147483648 || value > 2147483647 ||
                    (j > 0 && input[at + j - 1] >= value)) return -1;
        }
        at += size[id];
    }
    if (at != length) return -1;

    long[LISTS] tails = zeroed;
    long[LISTS] firsts = zeroed;
    for (usz i = 0; i < LISTS; i += 1) {
        tails[i] = input[base[i] + size[i] - 1];
        firsts[i] = input[base[i]];
    }
    for (usz i = 0; i < LISTS; i += 1) {
        for (usz j = i + 1; j < LISTS; j += 1) {
            if (tails[i] > tails[j]) { long temp = tails[i]; tails[i] = tails[j]; tails[j] = temp; }
            if (firsts[i] > firsts[j]) { long temp = firsts[i]; firsts[i] = firsts[j]; firsts[j] = temp; }
        }
    }
    long maximum_candidate = tails[1];
    long candidate = firsts[1];

    uint8[LISTS] color = {WHITE, WHITE, WHITE};
    usz[LISTS] cursor = {1, 1, 1};
    usz[LISTS] search_base = {1, 1, 1};
    usz[LISTS] search_low = {1, 1, 1};
    usz[LISTS] search_step = {1, 1, 1};
    usz[LISTS] search_probe = {1, 1, 1};
    usz[LISTS] representative = zeroed;
    bool[LISTS] representative_present = zeroed;
    for (usz i = 0; i < LISTS; i += 1) {
        if (input[base[i]] == candidate) color[i] = GREEN;
        else if (input[base[i]] > candidate) {
            color[i] = RED;
            representative_present[i] = true;
        }
    }

    long[MAX_VALUES] result = zeroed;
    usz result_count = 0;
    usz round_robin = 0;
    while (candidate <= maximum_candidate) {
        usz green_count = 0;
        usz red_count = 0;
        usz white_count = 0;
        for (usz i = 0; i < LISTS; i += 1) {
            if (color[i] == GREEN) green_count += 1;
            else if (color[i] == RED) red_count += 1;
            else white_count += 1;
        }
        if (green_count >= 2 || red_count >= 2) {
            if (green_count >= 2) { result[result_count] = candidate; result_count += 1; }
            usz recolor_count = white_count == 0 ? 1 : 0;
            for (usz i = 0; i < LISTS && recolor_count > 0; i += 1) {
                if (color[i] != GREEN) continue;
                color[i] = WHITE;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
                recolor_count -= 1;
            }
            for (usz i = 0; i < LISTS; i += 1) {
                if (color[i] != GREEN) continue;
                color[i] = RED;
                representative[i] = cursor[i];
                representative_present[i] = cursor[i] < size[i];
            }
            bool found = false;
            long next_candidate = 9223372036854775807;
            for (usz i = 0; i < LISTS; i += 1) {
                if (!representative_present[i]) continue;
                long value = input[base[i] + representative[i]];
                if (!found || value < next_candidate) { found = true; next_candidate = value; }
            }
            if (!found) break;
            candidate = next_candidate;
            for (usz i = 0; i < LISTS; i += 1) {
                if (color[i] != RED || !representative_present[i] ||
                        input[base[i] + representative[i]] != candidate) continue;
                color[i] = GREEN;
                representative_present[i] = false;
                cursor[i] = representative[i] + 1;
                search_base[i] = cursor[i];
                search_low[i] = cursor[i];
                search_step[i] = 1;
                search_probe[i] = cursor[i];
            }
            continue;
        }

        usz list_id = LISTS;
        for (usz offset = 0; offset < LISTS; offset += 1) {
            usz i = (round_robin + offset) % LISTS;
            if (color[i] == WHITE) { list_id = i; break; }
        }
        if (list_id == LISTS) break;
        round_robin = (list_id + 1) % LISTS;
        usz probe = search_probe[list_id];
        if (probe >= size[list_id]) probe = size[list_id] - 1;
        if (input[base[list_id] + probe] < candidate) {
            search_low[list_id] = probe + 1;
            if (probe + 1 == size[list_id]) {
                color[list_id] = RED;
                representative[list_id] = size[list_id];
                representative_present[list_id] = false;
            } else {
                search_step[list_id] *= 2;
                usz next_probe = search_base[list_id] + search_step[list_id] - 1;
                search_probe[list_id] = next_probe < size[list_id] ? next_probe : size[list_id] - 1;
            }
            continue;
        }
        usz low = search_low[list_id];
        usz high = probe + 1;
        while (low < high) {
            usz middle = low + (high - low) / 2;
            if (input[base[list_id] + middle] < candidate) low = middle + 1;
            else high = middle;
        }
        if (low < size[list_id] && input[base[list_id] + low] == candidate) {
            color[list_id] = GREEN;
            cursor[list_id] = low + 1;
        } else {
            color[list_id] = RED;
            representative[list_id] = low;
            representative_present[list_id] = low < size[list_id];
        }
    }

    usz output_bytes = 8 * (1 + result_count);
    if (output == null || capacity < output_bytes) return -2;
    put_i64_le(output, 0, (long)result_count);
    for (usz i = 0; i < result_count; i += 1) put_i64_le(output, 8 * (i + 1), result[i]);
    return (long)output_bytes;
}
