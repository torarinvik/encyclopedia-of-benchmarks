module negative_integers_sequence;

fn long negative_integers_sequence(long index) @export("negative_integers_sequence") {
    if (index < 0) return 0;
    return -index - 1;
}
