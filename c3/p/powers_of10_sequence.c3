module powers_of10_sequence;

fn long powers_of10_sequence(long index) @export("powers_of10_sequence") {
    if (index < 0 || index > 18) return -1;
    long value = 1;
    for (long i = 0; i < index; i += 1) value *= 10;
    return value;
}
