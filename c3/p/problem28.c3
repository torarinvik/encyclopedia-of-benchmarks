module problem28;

fn long problem28(long size) @export("problem28") {
    if (size < 0 || size > 100000) return -1;
    long total = 1;
    long layer_count = (size + 1) / 2;
    for (long layer = 1; layer < layer_count; layer++) {
        long odd_corner = 2 * layer + 1;
        long even_corner = 2 * layer;
        total += 4 * odd_corner * odd_corner - 6 * even_corner;
    }
    return total;
}
