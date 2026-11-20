#include <stddef.h>
#include <stdint.h>

enum { OA_MAX_JOBS = 2, OA_MAX_TIME = 4, OA_MAX_INPUT = 8,
       OA_MAX_SEGMENTS = 3, OA_MAX_OUTPUT_VALUES = 19,
       OA_MAX_OUTPUT_BYTES = 152 };

typedef struct { int64_t n, d; } oa_rat;
typedef struct { int64_t start, end, speed_n, speed_d; } oa_segment;

static int64_t oa_gcd(int64_t a, int64_t b) {
    while (b != 0) { int64_t r = a % b; a = b; b = r; }
    return a < 0 ? -a : a;
}
static oa_rat oa_make(int64_t n, int64_t d) {
    if (d < 0) { n = -n; d = -d; }
    int64_t g = oa_gcd(n, d);
    return (oa_rat){ n / g, d / g };
}
static oa_rat oa_add(oa_rat a, oa_rat b) { return oa_make(a.n*b.d + b.n*a.d, a.d*b.d); }
static oa_rat oa_sub(oa_rat a, oa_rat b) { return oa_make(a.n*b.d - b.n*a.d, a.d*b.d); }
static oa_rat oa_mul(oa_rat a, oa_rat b) { return oa_make(a.n*b.n, a.d*b.d); }
static oa_rat oa_div(oa_rat a, oa_rat b) { return oa_make(a.n*b.d, a.d*b.n); }
static int oa_cmp(oa_rat a, oa_rat b) {
    int64_t left = a.n*b.d, right = b.n*a.d;
    return (left > right) - (left < right);
}
static oa_rat oa_int(int64_t value) { return (oa_rat){ value, 1 }; }
static void oa_store(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at+b] = (uint8_t)(bits >> (8u*b));
}

static void oa_add_segment(oa_segment *segments, size_t *count,
                           int64_t start, int64_t end, oa_rat speed) {
    if (end <= start || speed.n <= 0) return;
    if (*count && segments[*count-1].end == start &&
        oa_cmp(speed, oa_make(segments[*count-1].speed_n,
                              segments[*count-1].speed_d)) == 0) {
        segments[*count-1].end = end;
        return;
    }
    segments[*count] = (oa_segment){start, end, speed.n, speed.d};
    ++*count;
}

int64_t oa_speed_scaling(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2u || length > OA_MAX_INPUT) return -1;
    if (input[0] < 1 || input[0] > OA_MAX_JOBS ||
        length != 1u + 3u*(size_t)input[0]) return -1;
    const size_t jobs = (size_t)input[0];
    int64_t release[OA_MAX_JOBS], deadline[OA_MAX_JOBS];
    oa_rat remaining[OA_MAX_JOBS] = {{0,1},{0,1}};
    oa_rat completion[OA_MAX_JOBS] = {{0,1},{0,1}};
    int completed[OA_MAX_JOBS] = {0,0};
    for (size_t j = 0; j < jobs; ++j) {
        release[j] = input[1u+3u*j]; deadline[j] = input[2u+3u*j];
        int64_t work = input[3u+3u*j];
        if (release[j] < 0 || release[j] >= deadline[j] || deadline[j] > OA_MAX_TIME ||
            work < 1 || work > 4) return -1;
    }

    oa_segment segments[OA_MAX_SEGMENTS];
    size_t segment_count = 0;
    oa_rat energy = oa_int(0);
    for (int64_t now = 0; now <= OA_MAX_TIME; ++now) {
        int has_arrival = 0;
        for (size_t j = 0; j < jobs; ++j) if (release[j] == now) {
            remaining[j] = oa_int(input[3u+3u*j]);
            has_arrival = 1;
        }
        if (!has_arrival) continue;
        int64_t next_release = OA_MAX_TIME + 1;
        for (size_t j = 0; j < jobs; ++j)
            if (release[j] > now && release[j] < next_release) next_release = release[j];

        int order[OA_MAX_JOBS], count = 0;
        for (size_t j = 0; j < jobs; ++j)
            if (remaining[j].n > 0 && deadline[j] > now) order[count++] = (int)j;
        for (int i = 1; i < count; ++i) {
            int value = order[i], k = i;
            while (k > 0 && (deadline[order[k-1]] > deadline[value] ||
                   (deadline[order[k-1]] == deadline[value] && order[k-1] > value))) {
                order[k] = order[k-1]; --k;
            }
            order[k] = value;
        }
        int64_t left = now;
        while (count > 0) {
            oa_rat prefix = oa_int(0), best = oa_int(0);
            int best_count = 0;
            for (int k = 1; k <= count; ++k) {
                prefix = oa_add(prefix, remaining[order[k-1]]);
                oa_rat density = oa_div(prefix, oa_int(deadline[order[k-1]]-left));
                if (best_count == 0 || oa_cmp(density, best) > 0) {
                    best = density; best_count = k;
                }
            }
            int64_t right = deadline[order[best_count-1]];
            int64_t stop = right < next_release ? right : next_release;
            oa_add_segment(segments, &segment_count, left, stop, best);
            oa_rat span = oa_int(stop-left);
            energy = oa_add(energy, oa_mul(oa_mul(oa_mul(best,best),best),span));
            oa_rat cursor = oa_int(left), stop_rat = oa_int(stop);
            for (int k = 0; k < best_count; ++k) {
                int j = order[k];
                oa_rat duration = oa_div(remaining[j], best);
                oa_rat finish = oa_add(cursor, duration);
                if (oa_cmp(finish, stop_rat) <= 0) {
                    completion[j] = finish; completed[j] = 1;
                    remaining[j] = oa_int(0); cursor = finish;
                } else {
                    remaining[j] = oa_sub(remaining[j], oa_mul(best, oa_sub(stop_rat,cursor)));
                    cursor = stop_rat;
                    break;
                }
            }
            if (stop < right) break;
            for (int k = best_count; k < count; ++k) order[k-best_count] = order[k];
            count -= best_count;
            left = right;
        }
    }
    for (size_t j = 0; j < jobs; ++j) if (!completed[j]) return -1;

    int64_t values[OA_MAX_OUTPUT_VALUES] = {0};
    size_t fields = 0;
    values[fields++] = (int64_t)segment_count;
    values[fields++] = energy.n; values[fields++] = energy.d;
    for (size_t s = 0; s < segment_count; ++s) {
        values[fields++] = segments[s].start; values[fields++] = segments[s].end;
        values[fields++] = segments[s].speed_n; values[fields++] = segments[s].speed_d;
    }
    for (size_t j = 0; j < jobs; ++j) {
        values[fields++] = completion[j].n; values[fields++] = completion[j].d;
    }
    size_t bytes = 8u*fields;
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[OA_MAX_OUTPUT_BYTES] = {0};
    for (size_t i = 0; i < fields; ++i) oa_store(staged,8u*i,values[i]);
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
