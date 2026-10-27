module point_pattern_translation_lex_scan;

const usz MAX_PATTERN = 6;
const usz MAX_TARGET = 8;
const long MAX_COORD = 16;

fn bool point_less(long ax, long ay, long bx, long by) {
    return ax < bx || (ax == bx && ay < by);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long point_pattern_translation_lex_scan(long* input, usz length, char* output, usz capacity)
        @export("point_pattern_translation_lex_scan") {
    if (input == null || length < 2 || length > 31) return -1;
    long pattern_raw = input[0], target_raw = input[1];
    if (pattern_raw < 1 || pattern_raw > MAX_PATTERN.long() || target_raw < 1 || target_raw > MAX_TARGET.long() || pattern_raw > target_raw) return -1;
    usz pattern_count = pattern_raw.usz(), target_count = target_raw.usz();
    if (length != 2 + 2 * (pattern_count + target_count)) return -1;
    long[MAX_PATTERN] px = zeroed, py = zeroed;
    long[MAX_TARGET] tx = zeroed, ty = zeroed;
    usz cursor = 2;
    for (usz i = 0; i < pattern_count; i += 1) {
        px[i] = input[cursor]; py[i] = input[cursor + 1]; cursor += 2;
        if (px[i] < -MAX_COORD || px[i] > MAX_COORD || py[i] < -MAX_COORD || py[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(px[i - 1], py[i - 1], px[i], py[i])) return -1;
    }
    for (usz i = 0; i < target_count; i += 1) {
        tx[i] = input[cursor]; ty[i] = input[cursor + 1]; cursor += 2;
        if (tx[i] < -MAX_COORD || tx[i] > MAX_COORD || ty[i] < -MAX_COORD || ty[i] > MAX_COORD) return -1;
        if (i > 0 && !point_less(tx[i - 1], ty[i - 1], tx[i], ty[i])) return -1;
    }
    if (output == null || capacity < 24) return -2;

    long found = 0, best_x = 0, best_y = 0;
    for (usz anchor = 0; anchor < target_count; anchor += 1) {
        long dx = tx[anchor] - px[0], dy = ty[anchor] - py[0];
        usz target_index = anchor + 1;
        bool matches = true;
        for (usz pattern_index = 1; pattern_index < pattern_count; pattern_index += 1) {
            long wanted_x = px[pattern_index] + dx, wanted_y = py[pattern_index] + dy;
            while (target_index < target_count && point_less(tx[target_index], ty[target_index], wanted_x, wanted_y)) target_index += 1;
            if (target_index >= target_count || tx[target_index] != wanted_x || ty[target_index] != wanted_y) { matches = false; break; }
            target_index += 1;
        }
        if (matches) { found = 1; best_x = dx; best_y = dy; break; }
    }
    char[24] staged = zeroed;
    store_i64_le(&staged[0], 0, found); store_i64_le(&staged[0], 8, best_x); store_i64_le(&staged[0], 16, best_y);
    for (usz byte = 0; byte < 24; byte += 1) output[byte] = staged[byte];
    return 24;
}
