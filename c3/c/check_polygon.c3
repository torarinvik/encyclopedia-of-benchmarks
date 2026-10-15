module check_polygon;

fn long check_polygon(long* values, usz length, char* output, usz output_capacity)
    @export("check_polygon") {
    if (values == null || length < 3 || length > 256) return -1;

    long total = 0;
    long largest = 0;
    for (usz index = 0; index < length; index++) {
        long side = values[index];
        if (side < 1 || side > 1000000000) return -1;
        total += side;
        if (side > largest) largest = side;
    }
    return largest < total - largest ? 1 : 0;
}
