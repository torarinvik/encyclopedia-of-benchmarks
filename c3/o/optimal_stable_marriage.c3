module optimal_stable_marriage;

const MAX_N = 8;
const MAX_INPUT_LENGTH = 129;

fn long optimal_stable_marriage(long* input, usz length, char* output, usz capacity) @export("optimal_stable_marriage") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    usz side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    usz[64] men_preferences;
    usz[64] women_rank;
    for (usz row = 0; row < 2 * n; row++) {
        bool[8] seen;
        for (usz id = 0; id < MAX_N; id++) seen[id] = false;
        usz start = row < n ? 1 + row * n : 1 + side_size + (row - n) * n;
        for (usz rank = 0; rank < n; rank++) {
            long value = input[start + rank];
            if (value < 0 || value >= (long)n || seen[(usz)value]) return -1;
            seen[(usz)value] = true;
            if (row < n) men_preferences[row * n + rank] = (usz)value;
            else women_rank[(row - n) * n + (usz)value] = rank;
        }
    }
    usz output_bytes = 16 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[8] final_partner;
    for (usz man = 0; man < n; man++) final_partner[man] = -1;
    for (usz threshold = 0; threshold < n; threshold++) {
        long[8] woman_partner;
        long[8] man_partner;
        usz[8] next_rank;
        usz[8] queue;
        for (usz i = 0; i < n; i++) {
            woman_partner[i] = -1;
            man_partner[i] = -1;
            next_rank[i] = 0;
            queue[i] = i;
        }
        usz head = 0, tail = 0, queued = n;
        while (queued > 0) {
            usz man = queue[head];
            head = (head + 1) % n;
            queued--;
            while (next_rank[man] < n) {
                usz rank = next_rank[man]++;
                usz woman = men_preferences[man * n + rank];
                if (rank > threshold || women_rank[woman * n + man] > threshold) continue;
                long incumbent = woman_partner[woman];
                if (incumbent < 0 || women_rank[woman * n + man] < women_rank[woman * n + (usz)incumbent]) {
                    woman_partner[woman] = (long)man;
                    man_partner[man] = (long)woman;
                    if (incumbent >= 0) {
                        man_partner[(usz)incumbent] = -1;
                        queue[tail] = (usz)incumbent;
                        tail = (tail + 1) % n;
                        queued++;
                    }
                    break;
                }
                queue[tail] = man;
                tail = (tail + 1) % n;
                queued++;
                break;
            }
        }
        usz matched = 0;
        for (usz man = 0; man < n; man++) if (man_partner[man] >= 0) matched++;
        if (matched == n) {
            for (usz man = 0; man < n; man++) final_partner[man] = man_partner[man];
            break;
        }
    }
    for (usz man = 0; man < n; man++) {
        long[2] pair = {(long)man, final_partner[man]};
        for (usz item = 0; item < 2; item++) {
            ulong bits = (ulong)pair[item];
            for (usz byte = 0; byte < 8; byte++) {
                output[(man * 2 + item) * 8 + byte] = (char)(bits & 255);
                bits >>= 8;
            }
        }
    }
    return (long)output_bytes;
}
