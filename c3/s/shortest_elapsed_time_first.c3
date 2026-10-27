module shortest_elapsed_time_first;

const usz MAX_JOBS = 8;
const usz MAX_INPUT = 18;
const usz MAX_OUTPUT = 112;

long shortest_elapsed_time_first(long* input, usz length, char* output, usz capacity)
        @export("shortest_elapsed_time_first") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long n64 = input[0];
    if (n64 < 0 || n64 > 8 || length != 1 + 2 * (usz)n64) return -1;
    usz n = (usz)n64;
    long[MAX_JOBS] release = zeroed, remaining = zeroed, attained = zeroed;
    for (usz job = 0; job < n; job++) {
        release[job] = input[1 + 2 * job];
        remaining[job] = input[2 + 2 * job];
        if (release[job] < 0 || release[job] > 16 || remaining[job] < 1 || remaining[job] > 12) return -1;
    }
    if (output == null) return -2;
    char[MAX_OUTPUT] trace = zeroed;
    usz time = 0, completed = 0;
    while (completed < n && time < MAX_OUTPUT) {
        usz chosen = n;
        for (usz job = 0; job < n; job++)
            if (release[job] <= (long)time && remaining[job] > 0 &&
                (chosen == n || attained[job] < attained[chosen])) chosen = job;
        if (chosen < n) {
            trace[time] = (char)(chosen + 1);
            attained[chosen] += 1;
            remaining[chosen] -= 1;
            if (remaining[chosen] == 0) completed += 1;
        }
        time += 1;
    }
    if (completed != n) return -1;
    if (capacity < time) return -2;
    for (usz t = 0; t < time; t++) output[t] = trace[t];
    return (long)time;
}
