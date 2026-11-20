module seven_sided_dice_from_five_sided_dice;

const usz MAX_DRAWS = 256;
const usz MAX_INPUT_LENGTH = MAX_DRAWS + 2;

fn long seven_sided_dice_from_five_sided_dice(
    long* input, usz length, char* output, usz capacity)
    @export("seven_sided_dice_from_five_sided_dice") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long draw_count_value = input[0];
    if (draw_count_value < 0 || draw_count_value > (long)MAX_DRAWS ||
        length != (usz)draw_count_value + 1) return -1;
    usz draw_count = (usz)draw_count_value;
    for (usz index = 0; index < draw_count; index += 1)
        if (input[index + 1] < 0 || input[index + 1] > 4) return -1;

    char[MAX_DRAWS] staged = zeroed;
    usz written = 0;
    long value = 0;
    long range = 1;
    for (usz index = 0; index < draw_count; index += 1) {
        value = 5 * value + input[index + 1];
        range *= 5;
        while (range >= 7) {
            long accepted = range - range % 7;
            if (value < accepted) {
                staged[written] = (char)(value % 7 + 1);
                written += 1;
                value /= 7;
                range = accepted / 7;
            } else {
                value -= accepted;
                range -= accepted;
            }
        }
    }

    if (output == null || capacity < written) return -2;
    for (usz index = 0; index < written; index += 1) output[index] = staged[index];
    return (long)written;
}
