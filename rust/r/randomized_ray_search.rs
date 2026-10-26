const MAX_RAYS: usize = 5;
const MAX_ROUNDS: usize = 32;
const MAX_INPUT: usize = 11;

unsafe fn store_i64_le(output: *mut u8, offset: usize, value: i64) {
    let bits = value as u64;
    for byte in 0..8 { *output.add(offset + byte) = ((bits >> (8 * byte)) & 255) as u8; }
}

#[no_mangle]
pub unsafe extern "C" fn randomized_ray_search(
    input_opt: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input_opt.is_null() || length < 5 || length > MAX_INPUT { return -1; }
    let input = std::slice::from_raw_parts(input_opt, length);
    let rays_raw = input[0];
    let growth = input[1];
    let initial = input[2];
    if rays_raw < 2 || rays_raw > MAX_RAYS as i64 || growth < 2 || growth > 4
        || initial < 1000 || initial >= growth * 1000 || length != rays_raw as usize + 5 { return -1; }
    let rays = rays_raw as usize;
    let mut permutation = [0usize; MAX_RAYS];
    let mut seen = [false; MAX_RAYS];
    for i in 0..rays {
        let ray = input[3 + i];
        if ray < 0 || ray >= rays_raw || seen[ray as usize] { return -1; }
        permutation[i] = ray as usize;
        seen[ray as usize] = true;
    }
    let target = input[3 + rays];
    let target_distance = input[4 + rays];
    if target < 0 || target >= rays_raw || target_distance < 1 || target_distance > 1_000_000_000 { return -1; }
    let mut distance = initial;
    let mut total = 0i64;
    let mut attempts = 0i64;
    let mut found = false;
    for round in 0..MAX_ROUNDS {
        let ray = permutation[round % rays];
        attempts += 1;
        if ray as i64 == target && target_distance <= distance {
            total += target_distance;
            found = true;
            break;
        }
        total += 2 * distance;
        distance *= growth;
    }
    if !found { return -1; }
    if output.is_null() || capacity < 16 { return -2; }
    store_i64_le(output, 0, attempts);
    store_i64_le(output, 8, total);
    16
}
