module simulated_annealing;

const usz MAX_PACKED_LENGTH = 366;
const long MAX_DRAWS = 176;
const long MAX_ITERATIONS = 22;
const long INVALID_RESULT = -1;

fn long score_i64(long x, long y) { return x * x + y * y; }

fn long simulated_annealing(long* packed, usz length) @export("simulated_annealing") {
    if (packed == null || length < 13 || length > MAX_PACKED_LENGTH) return INVALID_RESULT;
    long x0 = packed[0], y0 = packed[1], step = packed[2];
    long min_x = packed[3], max_x = packed[4], min_y = packed[5], max_y = packed[6];
    long find_max = packed[7], start_raw = packed[8], rate_raw = packed[9], threshold_raw = packed[10];
    long selection_count = packed[11];
    if (x0 < -16 || x0 > 16 || y0 < -16 || y0 > 16 || step < 1 || step > 4 ||
        min_x < -16 || max_x > 16 || min_x > max_x || min_y < -16 || max_y > 16 || min_y > max_y ||
        x0 < min_x || x0 > max_x || y0 < min_y || y0 > max_y || (find_max != 0 && find_max != 1) ||
        start_raw < 1000000 || start_raw > 10000000 || rate_raw < 100000 || rate_raw > 500000 ||
        threshold_raw < 1000000 || threshold_raw > 9999999 || threshold_raw >= start_raw ||
        selection_count < 0 || selection_count > MAX_DRAWS || selection_count > (long)(length - 13)) return INVALID_RESULT;

    usz selection_n = (usz)selection_count;
    usz acceptance_count_index = 12 + selection_n;
    long acceptance_count = packed[acceptance_count_index];
    if (acceptance_count < 0 || acceptance_count > MAX_DRAWS || length != 13 + selection_n + (usz)acceptance_count) return INVALID_RESULT;
    for (usz i = 0; i < selection_n; i++) if (packed[12 + i] < 0 || packed[12 + i] > 7) return INVALID_RESULT;
    usz acceptance_start = acceptance_count_index + 1;
    for (usz i = 0; i < (usz)acceptance_count; i++) {
        long draw = packed[acceptance_start + i];
        if (draw != 0 && draw != 999999) return INVALID_RESULT;
    }

    double current_temp = (double)start_raw / 1000000.0;
    double rate = (double)rate_raw / 1000000.0;
    double threshold = (double)threshold_raw / 1000000.0;
    long current_x = x0, current_y = y0, best_x = x0, best_y = y0;
    long best_score = score_i64(x0, y0);
    usz selection_cursor = 0, acceptance_cursor = 0;
    bool stopped = false;

    for (long iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
        long current_score = score_i64(current_x, current_y);
        if (current_score > best_score) { best_score = current_score; best_x = current_x; best_y = current_y; }
        long[8] neighbor_x = {current_x-step,current_x-step,current_x-step,current_x,current_x,current_x+step,current_x+step,current_x+step};
        long[8] neighbor_y = {current_y-step,current_y,current_y+step,current_y-step,current_y+step,current_y-step,current_y,current_y+step};
        usz remaining = 8;
        bool found = false;
        long next_x = 0, next_y = 0;
        while (!found && remaining > 0) {
            if (selection_cursor >= selection_n) return INVALID_RESULT;
            long rank = packed[12 + selection_cursor]; selection_cursor++;
            if ((usz)rank >= remaining) return INVALID_RESULT;
            usz selected = (usz)rank;
            long candidate_x = neighbor_x[selected], candidate_y = neighbor_y[selected];
            long raw_change = score_i64(candidate_x,candidate_y) - current_score;
            for (usz i = selected + 1; i < remaining; i++) { neighbor_x[i-1] = neighbor_x[i]; neighbor_y[i-1] = neighbor_y[i]; }
            remaining--;
            if (candidate_x < min_x || candidate_x > max_x || candidate_y < min_y || candidate_y > max_y) continue;
            long change = find_max == 1 ? raw_change : -raw_change;
            if (change > 0) found = true;
            else {
                if (acceptance_cursor >= (usz)acceptance_count) return INVALID_RESULT;
                long draw = packed[acceptance_start + acceptance_cursor]; acceptance_cursor++;
                if (change == 0 || draw == 0) found = true;
            }
            if (found) { next_x = candidate_x; next_y = candidate_y; }
        }
        current_temp = current_temp - current_temp * rate;
        if (current_temp < threshold || !found) { stopped = true; break; }
        current_x = next_x; current_y = next_y;
    }
    if (!stopped) return INVALID_RESULT;
    return (best_x + 16) * 33 + (best_y + 16);
}
