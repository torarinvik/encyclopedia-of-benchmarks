const MAX_INPUT: i64 = 12;

fn tak(x: i64, y: i64, z: i64) -> i64 {
    if y < x {
        return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
    }
    z
}

#[no_mangle]
pub extern "C" fn takeuchi(x: i64, y: i64, z: i64) -> i64 {
    if x < 0 || x > MAX_INPUT || y < 0 || y > MAX_INPUT || z < 0 || z > MAX_INPUT { return -1; }
    tak(x, y, z)
}
