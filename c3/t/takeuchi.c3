module takeuchi;

const MAX_INPUT = 12;

fn long tak(long x, long y, long z) {
    if (y < x) return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
    return z;
}

fn long takeuchi(long x, long y, long z) @export("takeuchi") {
    if (x < 0 || x > MAX_INPUT || y < 0 || y > MAX_INPUT || z < 0 || z > MAX_INPUT) return -1;
    return tak(x, y, z);
}
