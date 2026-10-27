module yds_speed_scaling;

const usz MAX_JOBS = 4;
const usz MAX_TIME = 8;
const usz MAX_INPUT = 13;
const usz MAX_OUTPUT = 152;

fn long gcd64(long a, long b) {
    while (b != 0) { long r = a % b; a = b; b = r; }
    return a;
}

fn void put64(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[at+byte] = (char)(bits & 255); bits >>= 8; }
}

long yds_speed_scaling(long* input, usz length, char* output, usz capacity)
        @export("yds_speed_scaling") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    if (n64 < 1 || n64 > (long)MAX_JOBS || length != 1 + 3*(usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_JOBS] release = zeroed, deadline = zeroed, work = zeroed;
    bool[MAX_JOBS] active = zeroed;
    for (usz j = 0; j < n; j += 1) {
        long r = input[1+3*j], d = input[2+3*j], w = input[3+3*j];
        if (r < 0 || r >= d || d > (long)MAX_TIME || w < 1 || w > 8) return -1;
        release[j] = r; deadline[j] = d; work[j] = w; active[j] = true;
    }
    long[MAX_OUTPUT/8] staged = zeroed;
    usz output_values = 3, stages = 0;
    long energy_num = 0, energy_den = 1;
    usz remaining = n;
    while (remaining > 0) {
        bool[MAX_TIME+1] release_seen = zeroed, deadline_seen = zeroed;
        for (usz j = 0; j < n; j += 1) if (active[j]) { release_seen[(usz)release[j]] = true; deadline_seen[(usz)deadline[j]] = true; }
        bool have_best = false;
        usz best_a = 0, best_b = 1;
        long best_work = 0, best_duration = 1;
        for (usz a = 0; a <= MAX_TIME; a += 1) {
            if (!release_seen[a]) continue;
            for (usz b = a+1; b <= MAX_TIME; b += 1) {
                if (!deadline_seen[b]) continue;
                long total = 0;
                for (usz j = 0; j < n; j += 1) if (active[j] && release[j] >= (long)a && deadline[j] <= (long)b) total += work[j];
                if (total == 0) continue;
                long duration = (long)(b-a);
                if (!have_best || total*best_duration > best_work*duration ||
                    (total*best_duration == best_work*duration && (a < best_a || (a == best_a && b < best_b)))) {
                    have_best = true; best_a = a; best_b = b; best_work = total; best_duration = duration;
                }
            }
        }
        if (!have_best) return -1;
        ulong job_mask = 0;
        for (usz j = 0; j < n; j += 1) if (active[j] && release[j] >= (long)best_a && deadline[j] <= (long)best_b) job_mask |= 1u << j;
        staged[output_values++] = (long)best_a;
        staged[output_values++] = (long)best_b;
        staged[output_values++] = best_work;
        staged[output_values++] = (long)job_mask;
        long term_num = best_work*best_work*best_work, term_den = best_duration*best_duration;
        long common = gcd64(energy_den, term_den);
        energy_num = energy_num*(term_den/common) + term_num*(energy_den/common);
        energy_den *= term_den/common;
        long energy_gcd = gcd64(energy_num, energy_den);
        energy_num /= energy_gcd; energy_den /= energy_gcd;
        for (usz j = 0; j < n; j += 1) {
            if (!active[j]) continue;
            if (release[j] >= (long)best_a && deadline[j] <= (long)best_b) { active[j] = false; remaining -= 1; }
            else {
                if (release[j] > (long)best_a && release[j] < (long)best_b) release[j] = (long)best_a;
                else if (release[j] >= (long)best_b) release[j] -= best_duration;
                if (deadline[j] > (long)best_a && deadline[j] < (long)best_b) deadline[j] = (long)best_a;
                else if (deadline[j] >= (long)best_b) deadline[j] -= best_duration;
            }
        }
        stages += 1;
    }
    staged[0] = (long)stages; staged[1] = energy_num; staged[2] = energy_den;
    usz output_bytes = 8*output_values;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT] bytes = zeroed;
    for (usz i = 0; i < output_values; i += 1) put64(&bytes[0],8*i,staged[i]);
    for (usz i = 0; i < output_bytes; i += 1) output[i] = bytes[i];
    return (long)output_bytes;
}
