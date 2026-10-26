// Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt.
#[no_mangle]
pub unsafe extern "C" fn gbbs_five_cycle_count(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    const MAX_N: usize = 16;
    const MAX_M: usize = 64;
    if input.is_null() || length < 2 || length > 2 + 2 * MAX_M { return -1; }
    let n64 = *input;
    let m64 = *input.add(1);
    if n64 < 1 || n64 > MAX_N as i64 || m64 < 0 || m64 > MAX_M as i64 { return -1; }
    let n = n64 as usize;
    let m = m64 as usize;
    if length != 2 + 2 * m { return -1; }
    let mut adjacent = [[false; MAX_N]; MAX_N];
    for edge in 0..m {
        let u64 = *input.add(2 + 2 * edge);
        let v64 = *input.add(3 + 2 * edge);
        if u64 < 0 || v64 <= u64 || v64 >= n64 { return -1; }
        let u = u64 as usize;
        let v = v64 as usize;
        if adjacent[u][v] { return -1; }
        adjacent[u][v] = true;
        adjacent[v][u] = true;
    }
    if output.is_null() || capacity < 8 { return -2; }

    let mut count = 0i64;
    for start in 0..n {
        for first in (start + 1)..n {
            for second in (start + 1)..n {
                if second == first { continue; }
                for third in (start + 1)..n {
                    if third == first || third == second { continue; }
                    for last in (first + 1)..n {
                        if last == second || last == third { continue; }
                        if adjacent[start][first] && adjacent[first][second] &&
                            adjacent[second][third] && adjacent[third][last] &&
                            adjacent[last][start] { count += 1; }
                    }
                }
            }
        }
    }
    let bits = count as u64;
    for byte in 0..8 { *output.add(byte) = ((bits >> (8 * byte)) & 255) as u8; }
    8
}
