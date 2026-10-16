export fn problem28(size: i64) i64 {
    if (size < 0 or size > 100000) return -1;
    var total: i64 = 1;
    const layer_count = @divTrunc(size + 1, 2);
    var layer: i64 = 1;
    while (layer < layer_count) : (layer += 1) {
        const odd_corner = 2 * layer + 1;
        const even_corner = 2 * layer;
        total += 4 * odd_corner * odd_corner - 6 * even_corner;
    }
    return total;
}
