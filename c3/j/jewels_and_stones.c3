module jewels_and_stones;

const MAX_JEWELS_LENGTH = 127;
const MAX_STONES_LENGTH = 4096;
const MAX_PACKED_LENGTH = 4225;

// Count stones whose ASCII byte appears in the unique-jewel set.
fn long jewels_and_stones(long* input, usz length) @export("jewels_and_stones") {
    if (input == null || length < 2 || length > MAX_PACKED_LENGTH) { return -1; }
    if (input[0] < 0 || input[0] > MAX_JEWELS_LENGTH || input[1] < 0 || input[1] > MAX_STONES_LENGTH) { return -1; }
    usz jewel_count = (usz)input[0];
    usz stone_count = (usz)input[1];
    if (length != 2 + jewel_count + stone_count) { return -1; }
    long[128] counts;
    for (usz value = 0; value < 128; value++) { counts[value] = 0; }
    for (usz index = 0; index < jewel_count; index++) {
        long value = input[2 + index];
        if (value < 1 || value > 127 || counts[(usz)value] != 0) { return -1; }
        counts[(usz)value] = 1;
    }
    long total = 0;
    usz stone_start = 2 + jewel_count;
    for (usz index = 0; index < stone_count; index++) {
        long value = input[stone_start + index];
        if (value < 1 || value > 127) { return -1; }
        total += counts[(usz)value];
    }
    return total;
}
