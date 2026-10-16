module braikenridge_maclaurin;

// Return the exact determinant using a 32-state subset dynamic program.
fn long determinant(usz coefficient, long* features)
{
    usz[30] columns = {1,2,3,4,5, 0,2,3,4,5, 0,1,3,4,5,
                       0,1,2,4,5, 0,1,2,3,5, 0,1,2,3,4};
    long[32] paths;
    for (usz mask = 0; mask < 32; mask++) paths[mask] = 0;
    paths[0] = 1;
    for (usz row = 0; row < 5; row++) {
        long[32] next;
        for (usz mask = 0; mask < 32; mask++) next[mask] = 0;
        for (usz mask = 0; mask < 32; mask++) {
            usz selected = 0;
            for (usz bit = 0; bit < 5; bit++) selected += (mask >> bit) & 1;
            if (selected != row || paths[mask] == 0) continue;
            for (usz column = 0; column < 5; column++) {
                usz bit = (usz)1 << column;
                if ((mask & bit) != 0) continue;
                usz inversions = 0;
                for (usz previous = column + 1; previous < 5; previous++) {
                    inversions += (mask >> previous) & 1;
                }
                long term = paths[mask] * features[row * 6 + columns[coefficient * 5 + column]];
                next[mask | bit] += (inversions & 1) != 0 ? -term : term;
            }
        }
        for (usz mask = 0; mask < 32; mask++) paths[mask] = next[mask];
    }
    return paths[31];
}

fn long braikenridge_maclaurin_construction(long* values, usz length,
        char* output, usz output_capacity) @export("braikenridge_maclaurin_construction")
{
    if (values == null || length != 10) return -2;
    long[30] features;
    for (usz point = 0; point < 5; point++) {
        long x = values[2 * point];
        long y = values[2 * point + 1];
        if (x < -10 || x > 10 || y < -10 || y > 10) return -2;
        features[point * 6] = x * x;
        features[point * 6 + 1] = x * y;
        features[point * 6 + 2] = y * y;
        features[point * 6 + 3] = x;
        features[point * 6 + 4] = y;
        features[point * 6 + 5] = 1;
    }
    long[6] coefficients;
    for (usz index = 0; index < 6; index++) {
        long value = determinant(index, &features[0]);
        coefficients[index] = index % 2 == 0 ? value : -value;
    }
    if (output == null || output_capacity < 48) return -2;
    for (usz index = 0; index < 6; index++) {
        ulong bits = (ulong)coefficients[index];
        for (usz byte = 0; byte < 8; byte++) output[index * 8 + byte] = (char)(bits >> (8 * byte));
    }
    return 6;
}
