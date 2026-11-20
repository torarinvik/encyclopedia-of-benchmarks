const MAX_N = 64;
const MAX_INPUT = 66;

fn long asteroid_collision_stack(long* input, usz length, char* output, usz capacity)
    @export("asteroid_collision_stack") {
    if (input == null || length == 0 || length > MAX_INPUT) return -1;
    long n_word = input[0];
    if (n_word < 0 || n_word > MAX_N || length != (usz)n_word + 1) return -1;

    long[MAX_N] stack = {};
    usz top = 0;
    for (usz i = 0; i < (usz)n_word; i++) {
        long word = input[i + 1];
        if (word == 0 || word < -127 || word > 127) return -1;
        long incoming = word;
        bool alive = true;
        while (alive && top > 0 && stack[top - 1] > 0 && incoming < 0) {
            long left_size = stack[top - 1];
            long right_size = -incoming;
            if (left_size < right_size) top--;
            else if (left_size == right_size) {
                top--;
                alive = false;
            } else alive = false;
        }
        if (alive) {
            stack[top] = incoming;
            top++;
        }
    }

    usz required = top + 1;
    if (output == null || capacity < required) return -2;
    output[0] = (char)top;
    for (usz i = 0; i < top; i++) output[i + 1] = (char)(stack[i] & 255);
    return (long)required;
}
