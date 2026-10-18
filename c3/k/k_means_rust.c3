module k_means_rust;

const long U53_MAX = 9007199254740991L;
const double U53_DENOMINATOR = 9007199254740992.0;

fn long k_means_rust(long* input, usz length) @export("k_means_rust") {
    if (input == null || length != 10 || input[0] != 4) return -1L;
    long max_iter = input[1];
    if (max_iter < 1 || max_iter > 16) return -1L;
    long draw0 = input[2];
    long draw1 = input[4];
    if (input[3] != 0 || input[5] != 0 || draw0 < 0 || draw0 > U53_MAX ||
        draw1 < 0 || draw1 > U53_MAX || draw0 == draw1) return -1L;

    double[4] points;
    for (usz index = 0; index < 4; index++) {
        long coordinate = input[index + 6];
        if (coordinate < -16 || coordinate > 16 ||
            (index > 0 && input[index + 5] >= coordinate)) return -1L;
        points[index] = (double)coordinate;
    }
    if (input[7] >= 0 || input[8] <= 1) return -1L;

    double[4] centers = {
        (double)draw0 / U53_DENOMINATOR, 0.0,
        (double)draw1 / U53_DENOMINATOR, 0.0,
    };
    long[4] labels = zeroed;
    for (long pass = 0; pass < max_iter; pass++) {
        double[4] sums = zeroed;
        usz[2] counts = zeroed;
        for (usz index = 0; index < 4; index++) {
            double dx0 = points[index] - centers[0];
            double dy0 = -centers[1];
            double dx1 = points[index] - centers[2];
            double dy1 = -centers[3];
            double distance0 = dx0 * dx0 + dy0 * dy0;
            double distance1 = dx1 * dx1 + dy1 * dy1;
            usz cluster = distance1 < distance0 ? 1 : 0;
            labels[index] = (long)cluster;
            sums[cluster * 2] = sums[cluster * 2] + points[index];
            sums[cluster * 2 + 1] = sums[cluster * 2 + 1] + 0.0;
            counts[cluster]++;
        }
        if (counts[0] == 0 || counts[1] == 0) return -1L;
        for (usz cluster = 0; cluster < 2; cluster++) {
            centers[cluster * 2] = sums[cluster * 2] / (double)counts[cluster];
            centers[cluster * 2 + 1] = sums[cluster * 2 + 1] / (double)counts[cluster];
        }
    }
    long packed = 0;
    for (usz index = 0; index < 4; index++) packed += labels[index] * (1L << index);
    return packed;
}
