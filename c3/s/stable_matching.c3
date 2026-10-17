module stable_matching;

const MAX_N = 8;
const MAX_INPUT_LENGTH = 129;

fn long stable_matching(long* input, usz length, char* output, usz capacity) @export("stable_matching") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    usz n = (usz)input[0];
    usz side_size = n * n;
    if (length != 1 + 2 * side_size) return -1;

    long[64] men_preferences;
    long[64] women_rank;
    for (usz row = 0; row < 2 * n; row++) {
        bool[8] seen;
        for (usz id = 0; id < MAX_N; id++) seen[id] = false;
        usz row_start = row < n ? 1 + row * n : 1 + side_size + (row - n) * n;
        for (usz rank = 0; rank < n; rank++) {
            long participant = input[row_start + rank];
            if (participant < 0 || participant >= (long)n || seen[(usz)participant]) return -1;
            seen[(usz)participant] = true;
            if (row < n) men_preferences[row * n + rank] = participant;
            else women_rank[(row - n) * n + (usz)participant] = (long)rank;
        }
    }

    usz output_bytes = 16 * n;
    if (output == null || capacity < output_bytes) return -2;

    long[8] woman_partner;
    long[8] man_partner;
    usz[8] next_proposal;
    usz[8] free_queue;
    for (usz index = 0; index < n; index++) {
        woman_partner[index] = -1;
        man_partner[index] = -1;
        next_proposal[index] = 0;
        free_queue[index] = index;
    }
    usz head = 0, tail = 0, queue_count = n;
    while (queue_count > 0) {
        usz man = free_queue[head];
        head = (head + 1) % n;
        queue_count--;
        usz rank = next_proposal[man]++;
        usz woman = (usz)men_preferences[man * n + rank];
        long incumbent = woman_partner[woman];
        if (incumbent < 0) {
            woman_partner[woman] = (long)man;
            man_partner[man] = (long)woman;
        } else if (women_rank[woman * n + man] < women_rank[woman * n + (usz)incumbent]) {
            woman_partner[woman] = (long)man;
            man_partner[man] = (long)woman;
            man_partner[(usz)incumbent] = -1;
            free_queue[tail] = (usz)incumbent;
            tail = (tail + 1) % n;
            queue_count++;
        } else {
            free_queue[tail] = man;
            tail = (tail + 1) % n;
            queue_count++;
        }
    }

    for (usz man = 0; man < n; man++) {
        for (usz item = 0; item < 2; item++) {
            long participant = item == 0 ? (long)man : man_partner[man];
            ulong bits = (ulong)participant;
            for (usz byte = 0; byte < 8; byte++) {
                output[(man * 2 + item) * 8 + byte] = (char)(bits & 255);
                bits >>= 8;
            }
        }
    }
    return (long)output_bytes;
}
