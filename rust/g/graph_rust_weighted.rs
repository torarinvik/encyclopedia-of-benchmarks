const MAX_VERTICES: i64 = 64;
const MAX_EDGES: i64 = 256;

fn put_i64(output: &mut [u8], offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 {
        output[offset + byte] = (bits >> (8 * byte)) as u8;
    }
}

#[no_mangle]
pub unsafe extern "C" fn graph_rust_weighted(
    input: *const i64,
    length: usize,
    output: *mut u8,
    capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 {
        return -1;
    }
    let values = std::slice::from_raw_parts(input, length);
    let nv = values[0];
    let mv = values[1];
    if nv < 0 || nv > MAX_VERTICES || mv < 0 || mv > MAX_EDGES || length != 2 + 3 * mv as usize {
        return -1;
    }
    let n = nv as usize;
    let m = mv as usize;
    for edge in 0..m {
        let u = values[2 + 3 * edge];
        let v = values[3 + 3 * edge];
        let weight = values[4 + 3 * edge];
        if u < 0 || u >= nv || v < 0 || v >= nv || weight < i32::MIN as i64 || weight > i32::MAX as i64 {
            return -1;
        }
    }
    let required = (1 + n + 4 * m) * 8;
    if output.is_null() || capacity < required {
        return -2;
    }
    let out = std::slice::from_raw_parts_mut(output, required);
    let mut cursor = 0usize;
    put_i64(out, cursor * 8, nv);
    cursor += 1;
    for vertex in 0..n {
        let mut degree = 0usize;
        for edge in 0..m {
            if values[2 + 3 * edge] == vertex as i64 {
                degree += 1;
            }
            if values[3 + 3 * edge] == vertex as i64 {
                degree += 1;
            }
        }
        put_i64(out, cursor * 8, degree as i64);
        cursor += 1;
        for edge in 0..m {
            let u = values[2 + 3 * edge];
            let v = values[3 + 3 * edge];
            let weight = values[4 + 3 * edge];
            if u == vertex as i64 {
                put_i64(out, cursor * 8, v);
                cursor += 1;
                put_i64(out, cursor * 8, weight);
                cursor += 1;
            }
            if v == vertex as i64 {
                put_i64(out, cursor * 8, u);
                cursor += 1;
                put_i64(out, cursor * 8, weight);
                cursor += 1;
            }
        }
    }
    required as i64
}
