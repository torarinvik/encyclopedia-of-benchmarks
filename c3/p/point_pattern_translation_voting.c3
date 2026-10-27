module point_pattern_translation_voting;

const usz MAX_PATTERN = 6;
const usz MAX_TARGET = 8;
const usz MAX_PAIRS = 48;
const long MAX_COORD = 16;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long point_pattern_translation_voting(long* input, usz length, char* output, usz capacity)
        @export("point_pattern_translation_voting") {
    if (input == null || length < 2 || length > 31) return -1;
    long pattern_raw = input[0], target_raw = input[1];
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN.long() || target_raw < 1 || target_raw > MAX_TARGET.long()) return -1;
    usz pattern_count = pattern_raw.usz(), target_count = target_raw.usz();
    if (length != 2 + 2 * (pattern_count + target_count)) return -1;
    long[MAX_PATTERN] px = zeroed, py = zeroed;
    long[MAX_TARGET] tx = zeroed, ty = zeroed;
    usz cursor = 2;
    for (usz i = 0; i < pattern_count; i += 1) {
        px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2;
        if (px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD) return -1;
        for (usz j = 0; j < i; j += 1) if (px[i] == px[j] && py[i] == py[j]) return -1;
    }
    for (usz i = 0; i < target_count; i += 1) {
        tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2;
        if (tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD) return -1;
        for (usz j = 0; j < i; j += 1) if (tx[i] == tx[j] && ty[i] == ty[j]) return -1;
    }
    if (output == null) return -2;

    long[MAX_PAIRS] dx = zeroed, dy = zeroed;
    usz pair_count = 0;
    for (usz p = 0; p < pattern_count; p += 1) {
        for (usz t = 0; t < target_count; t += 1) {
            dx[pair_count] = tx[t] - px[p]; dy[pair_count] = ty[t] - py[p]; pair_count += 1;
        }
    }
    for (usz i = 1; i < pair_count; i += 1) {
        long key_x = dx[i], key_y = dy[i];
        usz j = i;
        while (j > 0 && (dx[j - 1] > key_x || (dx[j - 1] == key_x && dy[j - 1] > key_y))) {
            dx[j] = dx[j - 1]; dy[j] = dy[j - 1]; j -= 1;
        }
        dx[j] = key_x; dy[j] = key_y;
    }
    long best_count = 0, best_x = dx[0], best_y = dy[0];
    usz i = 0;
    while (i < pair_count) {
        usz ending = i + 1;
        while (ending < pair_count && dx[ending] == dx[i] && dy[ending] == dy[i]) ending += 1;
        if (ending - i > best_count.usz()) { best_count = (ending - i).long(); best_x = dx[i]; best_y = dy[i]; }
        i = ending;
    }
    if (capacity < 24) return -2;
    char[24] staged = zeroed;
    store_i64_le(&staged[0], 0, best_count);
    store_i64_le(&staged[0], 8, best_x);
    store_i64_le(&staged[0], 16, best_y);
    for (usz byte = 0; byte < 24; byte += 1) output[byte] = staged[byte];
    return 24;
}
