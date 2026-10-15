module longest_square_streak;

const MAX_INPUT_LENGTH = 100000;
const MAX_VALUE = 100000;
const REQUIRED_WORKSPACE = 4 * (MAX_VALUE + 1);

fn int read_state(char* workspace, usz value) {
    usz position = 4 * value;
    return (((int)workspace[position]) & 255) |
        ((((int)workspace[position + 1]) & 255) << 8) |
        ((((int)workspace[position + 2]) & 255) << 16) |
        ((((int)workspace[position + 3]) & 255) << 24);
}

fn void write_state(char* workspace, usz value, int state) {
    usz position = 4 * value;
    workspace[position] = (char)(state & 255);
    workspace[position + 1] = (char)((state >> 8) & 255);
    workspace[position + 2] = (char)((state >> 16) & 255);
    workspace[position + 3] = (char)((state >> 24) & 255);
}

fn long streak_from(char* workspace, usz value) {
    int state = read_state(workspace, value);
    if (state > 1) return (long)(state - 1);
    long length = 1;
    ulong square = (ulong)value * (ulong)value;
    if (square <= MAX_VALUE && read_state(workspace, (usz)square) != 0) {
        length += streak_from(workspace, (usz)square);
    }
    write_state(workspace, value, (int)(length + 1));
    return length;
}

fn long longest_square_streak(long* values, usz length, char* workspace,
        usz workspace_capacity) @export("longest_square_streak") {
    if (values == null || length < 3 || length > MAX_INPUT_LENGTH + 1 ||
        values[0] < 2 || values[0] > MAX_INPUT_LENGTH || length != (usz)values[0] + 1) return -1;
    usz count = (usz)values[0];
    for (usz index = 0; index < count; index++) {
        if (values[index + 1] < 2 || values[index + 1] > MAX_VALUE) return -1;
    }
    if (workspace == null || workspace_capacity < REQUIRED_WORKSPACE) return -2;
    for (usz byte_index = 0; byte_index < REQUIRED_WORKSPACE; byte_index++) workspace[byte_index] = 0;
    for (usz index = 0; index < count; index++) write_state(workspace, (usz)values[index + 1], 1);

    long longest = 1;
    for (usz index = 0; index < count; index++) {
        long found = streak_from(workspace, (usz)values[index + 1]);
        if (found > longest) longest = found;
    }
    return longest >= 2 ? longest : -1;
}
