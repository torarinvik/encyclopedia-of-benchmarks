module all_ones_sequence;

fn long all_ones_sequence(long index) @export("all_ones_sequence") {
    if (index < 0) return -1;
    return 1;
}
