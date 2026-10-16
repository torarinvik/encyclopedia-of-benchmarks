module dice_thrower;

const usz MAX_TARGET = 8;

fn usz required_bytes(usz remaining, usz depth) {
    if (remaining == 0) return depth + 1;
    usz total = 0;
    usz maximum_face = remaining < 6 ? remaining : 6;
    for (usz face = 1; face <= maximum_face; face++)
        total += required_bytes(remaining - face, depth + 1);
    return total;
}

fn void emit_combinations(usz remaining, usz depth, uint8* digits,
                          uint8* output, usz* position) {
    if (remaining == 0) {
        for (usz index = 0; index < depth; index++) output[(*position)++] = digits[index];
        output[(*position)++] = '\n';
        return;
    }
    usz maximum_face = remaining < 6 ? remaining : 6;
    for (usz face = 1; face <= maximum_face; face++) {
        digits[depth] = (uint8)('0' + face);
        emit_combinations(remaining - face, depth + 1, digits, output, position);
    }
}

fn long dice_thrower(long* values, usz length, uint8* output, usz output_capacity) @export("dice_thrower") {
    if (values == null || length != 1 || values[0] < 0 || values[0] > MAX_TARGET) return -1;
    usz target = (usz)values[0];
    usz needed = required_bytes(target, 0);
    if (output_capacity < needed || output == null) return -2;
    uint8[MAX_TARGET] digits;
    usz position = 0;
    emit_combinations(target, 0, &digits, output, &position);
    return (long)position;
}
