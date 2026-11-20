use std::cmp::Ordering;

fn reverse_route(route: &mut [usize; 7], length: usize) {
    route[..length].reverse();
}
fn compare_routes(a: &[usize; 7], an: usize, b: &[usize; 7], bn: usize) -> Ordering {
    a[..an].cmp(&b[..bn])
}
fn put_i64(output: &mut [u8], value: i64) {
    output.copy_from_slice(&value.to_le_bytes());
}

#[no_mangle]
pub unsafe extern "C" fn clarke_wright_savings_cvrp(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 74 { return -1; }
    let words = std::slice::from_raw_parts(input, length);
    let (n0, cap0) = (words[0], words[1]);
    if !(0..=7).contains(&n0) || !(1..=100).contains(&cap0) { return -1; }
    let n = n0 as usize;
    let cap = cap0;
    let width = n + 1;
    if length != 2 + n + width * width { return -1; }
    let mut demand = [0i64; 8];
    for c in 1..=n {
        demand[c] = words[1 + c];
        if demand[c] < 1 || demand[c] > cap { return -1; }
    }
    let mut distance = [[0i64; 8]; 8];
    let offset = 2 + n;
    for i in 0..width { for j in 0..width {
        let d = words[offset + i * width + j];
        if !(0..=1000).contains(&d) || i == j && d != 0 { return -1; }
        distance[i][j] = d;
    }}
    for i in 0..width { for j in i + 1..width {
        if distance[i][j] != distance[j][i] { return -1; }
    }}

    let mut routes = [[0usize; 7]; 7];
    let mut route_length = [0usize; 7];
    let mut load = [0i64; 7];
    let mut active = [false; 7];
    for r in 0..n { routes[r][0] = r + 1; route_length[r] = 1; load[r] = demand[r + 1]; active[r] = true; }
    let mut pairs = [(0i64, 0usize, 0usize); 21];
    let mut pair_count = 0;
    for i in 1..=n { for j in i + 1..=n {
        pairs[pair_count] = (distance[0][i] + distance[0][j] - distance[i][j], i, j);
        pair_count += 1;
    }}
    pairs[..pair_count].sort_by(|a, b| b.0.cmp(&a.0).then(a.1.cmp(&b.1)).then(a.2.cmp(&b.2)));
    for &(saving, i, j) in &pairs[..pair_count] {
        if saving <= 0 { break; }
        let (mut ri, mut rj, mut pi, mut pj) = (7usize, 7usize, 0usize, 0usize);
        for r in 0..n { if active[r] { for at in 0..route_length[r] {
            if routes[r][at] == i { ri = r; pi = at; }
            if routes[r][at] == j { rj = r; pj = at; }
        }}}
        if ri == rj || ri == 7 || rj == 7 { continue; }
        if (pi != 0 && pi + 1 != route_length[ri]) || (pj != 0 && pj + 1 != route_length[rj]) || load[ri] + load[rj] > cap { continue; }
        if pi == 0 { reverse_route(&mut routes[ri], route_length[ri]); }
        if pj + 1 == route_length[rj] { reverse_route(&mut routes[rj], route_length[rj]); }
        let old_i = route_length[ri];
        for at in 0..route_length[rj] { routes[ri][old_i + at] = routes[rj][at]; }
        route_length[ri] += route_length[rj]; load[ri] += load[rj];
        active[rj] = false; route_length[rj] = 0; load[rj] = 0;
    }

    let mut final_routes = [[0usize; 7]; 7];
    let mut final_length = [0usize; 7];
    let mut count = 0;
    for r in 0..n { if active[r] {
        let mut reverse_first = false;
        for at in 0..route_length[r] {
            let a = routes[r][at];
            let b = routes[r][route_length[r] - 1 - at];
            if a != b { reverse_first = a > b; break; }
        }
        if reverse_first { reverse_route(&mut routes[r], route_length[r]); }
        final_routes[count] = routes[r]; final_length[count] = route_length[r]; count += 1;
    }}
    for i in 0..count { for j in i + 1..count {
        if compare_routes(&final_routes[i], final_length[i], &final_routes[j], final_length[j]) == Ordering::Greater {
            final_routes.swap(i, j); final_length.swap(i, j);
        }
    }}
    let mut result = [0i64; 15]; let mut used = 0;
    result[used] = count as i64; used += 1;
    for r in 0..count {
        result[used] = final_length[r] as i64; used += 1;
        for at in 0..final_length[r] { result[used] = final_routes[r][at] as i64; used += 1; }
    }
    let bytes = used * 8;
    if output.is_null() || capacity < bytes { return -2; }
    let encoded = std::slice::from_raw_parts_mut(output, bytes);
    for i in 0..used { put_i64(&mut encoded[i * 8..(i + 1) * 8], result[i]); }
    bytes as i64
}
