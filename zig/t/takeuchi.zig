const MAX_INPUT: i64 = 12;

fn tak(x: i64, y: i64, z: i64) i64 {
    if (y < x) return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
    return z;
}

export fn takeuchi(x: i64, y: i64, z: i64) i64 {
    if (x < 0 or x > MAX_INPUT or y < 0 or y > MAX_INPUT or z < 0 or z > MAX_INPUT) return -1;
    return tak(x, y, z);
}
