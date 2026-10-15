module aho_corasick;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const usz MAX_PATTERNS = 16;
const usz MAX_PATTERN_LENGTH = 32;
const usz MAX_TEXT_LENGTH = 256;
const usz MAX_NODES = 1 + MAX_PATTERNS * MAX_PATTERN_LENGTH;
const usz ALPHABET = 128;

fn long aho_corasick(long* input, usz length, char* output, usz output_capacity) @export("aho_corasick") {
    if (input == null || length < 3 || input[0] < 1 || input[0] > (long)MAX_PATTERNS || input[1] < 0 || input[1] > (long)MAX_TEXT_LENGTH) return -1;
    usz pattern_count = (usz)input[0];
    if (length < 2 + pattern_count) return -1;
    usz[MAX_PATTERNS] starts;
    usz text_start = 2 + pattern_count;
    for (usz p = 0; p < pattern_count; p++) {
        if (input[2 + p] < 1 || input[2 + p] > (long)MAX_PATTERN_LENGTH) return -1;
        usz size = (usz)input[2 + p];
        if (text_start + size > length) return -1;
        starts[p] = text_start;
        for (usz i = 0; i < size; i++) if (input[starts[p] + i] < 1 || input[starts[p] + i] > 127) return -1;
        for (usz q = 0; q < p; q++) {
            if (input[2 + q] != (long)size) continue;
            usz i = 0;
            while (i < size && input[starts[q] + i] == input[starts[p] + i]) i++;
            if (i == size) return -1;
        }
        text_start += size;
    }
    usz text_length = (usz)input[1];
    if (text_start + text_length != length) return -1;
    for (usz i = 0; i < text_length; i++) if (input[text_start + i] < 1 || input[text_start + i] > 127) return -1;
    usz output_size = pattern_count * 8;
    if (output_capacity < output_size || output == null) return -2;

    int* next = (int*)malloc(MAX_NODES * ALPHABET * 4);
    if (next == null) return -3;
    defer free(next);
    int[MAX_NODES] failure, terminal, queue;
    for (usz n = 0; n < MAX_NODES; n++) {
        failure[n] = 0; terminal[n] = -1;
        for (usz ch = 0; ch < ALPHABET; ch++) next[n * ALPHABET + ch] = -1;
    }
    usz nodes = 1;
    for (usz p = 0; p < pattern_count; p++) {
        int state = 0;
        for (usz i = 0; i < (usz)input[2 + p]; i++) {
            usz ch = (usz)input[starts[p] + i];
            usz slot = (usz)state * ALPHABET + ch;
            if (next[slot] == -1) { next[slot] = (int)nodes; nodes++; }
            state = next[slot];
        }
        terminal[state] = (int)p;
    }
    usz head = 0;
    usz tail = 0;
    for (usz ch = 1; ch < ALPHABET; ch++) if (next[ch] != -1) { queue[tail] = next[ch]; tail++; }
    while (head < tail) {
        int state = queue[head]; head++;
        for (usz ch = 1; ch < ALPHABET; ch++) {
            int child = next[(usz)state * ALPHABET + ch];
            if (child == -1) continue;
            int suffix = failure[state];
            while (suffix != 0 && next[(usz)suffix * ALPHABET + ch] == -1) suffix = failure[suffix];
            int suffix_transition = next[(usz)suffix * ALPHABET + ch];
            if (suffix_transition != -1) suffix = suffix_transition;
            failure[child] = suffix; queue[tail] = child; tail++;
        }
    }
    long[MAX_PATTERNS] counts;
    for (usz p = 0; p < MAX_PATTERNS; p++) counts[p] = 0;
    int state = 0;
    for (usz i = 0; i < text_length; i++) {
        usz ch = (usz)input[text_start + i];
        while (state != 0 && next[(usz)state * ALPHABET + ch] == -1) state = failure[state];
        int transition = next[(usz)state * ALPHABET + ch];
        if (transition != -1) state = transition;
        int match = state;
        while (match != 0) {
            if (terminal[match] >= 0) counts[terminal[match]]++;
            match = failure[match];
        }
    }
    for (usz p = 0; p < pattern_count; p++) for (usz b = 0; b < 8; b++) output[p * 8 + b] = (char)((counts[p] >> (8 * b)) & 255);
    return (long)output_size;
}
