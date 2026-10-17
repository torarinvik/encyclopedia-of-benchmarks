module matchdimensions;

const long MATCHDIMENSIONS_MAX_DIMENSION = 65535;

fn long matchdimensions(long* values, usz length) @export("matchdimensions") {
    if (values == null || length != 4) return -1;
    for (usz index = 0; index < 4; index++) {
        if (values[index] < 0 || values[index] > MATCHDIMENSIONS_MAX_DIMENSION) return -1;
    }
    return values[0] == values[2] && values[1] == values[3] ? 1 : 0;
}
