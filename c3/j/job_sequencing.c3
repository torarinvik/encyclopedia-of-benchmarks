module job_sequencing;

const usz MAX_JOBS = 32;
const usz MAX_INPUT_LENGTH = 1 + 3 * MAX_JOBS + 1;
const long MAX_PROFIT = 1000000;

fn long job_sequencing(long* input, usz length, char* output, usz capacity) @export("job_sequencing") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH || input[0] < 1 || input[0] > 32) return -1;
    usz n = (usz)input[0];
    if (length != 1 + 3 * n) return -1;
    char[128] seen = {0};
    long previous_profit = MAX_PROFIT + 1;
    for (usz i = 0; i < n; i++) {
        long id = input[1 + 3 * i], deadline = input[2 + 3 * i], profit = input[3 + 3 * i];
        bool letter = (id >= 65 && id <= 90) || (id >= 97 && id <= 122);
        if (!letter || seen[id] != 0 || deadline < 1 || deadline > (long)n || profit < 1 || profit > MAX_PROFIT || profit >= previous_profit) return -1;
        seen[id] = 1; previous_profit = profit;
    }
    char[MAX_JOBS] slots = {0};
    long total_profit = 0;
    for (usz i = 0; i < n; i++) {
        usz deadline = (usz)input[2 + 3 * i];
        for (usz remaining = deadline; remaining > 0; remaining--) {
            usz slot = remaining - 1;
            if (slots[slot] == 0) { slots[slot] = (char)input[1 + 3 * i]; total_profit += input[3 + 3 * i]; break; }
        }
    }
    usz count = 0; for (usz i = 0; i < n; i++) if (slots[i] != 0) count++;
    usz required = 9 + count;
    if (output == null || capacity < required) return -2;
    output[0] = (char)count;
    for (usz i = 0; i < 8; i++) output[1 + i] = (char)((total_profit >> (8 * i)) & 255);
    usz written = 9; for (usz i = 0; i < n; i++) if (slots[i] != 0) output[written++] = slots[i];
    return (long)required;
}
