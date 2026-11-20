// Clean-room McCreight radix priority-search-tree profile.
const MAX_N: usize = 8;
const MAX_Q: usize = 7;
const X_DOMAIN: usize = 32;

#[no_mangle]
pub unsafe extern "C" fn priority_search_tree_three_sided_reporting(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length < 2 || length > 48 { return -1; }
    let n64 = *input;
    let q64 = *input.add(1);
    if n64 < 0 || n64 > MAX_N as i64 || q64 < 0 || q64 > MAX_Q as i64 ||
        length != 2 + 3 * n64 as usize + 3 * q64 as usize { return -1; }
    let n = n64 as usize;
    let q = q64 as usize;
    let mut nx = [0i64; MAX_N];
    let mut ny = [0i64; MAX_N];
    let mut nl = [0i64; MAX_N];
    let mut nlo = [0i64; MAX_N];
    let mut nhi = [0i64; MAX_N];
    let mut left = [-1i32; MAX_N];
    let mut right = [-1i32; MAX_N];
    let mut seen_x = [false; X_DOMAIN];
    let mut seen_label = [false; MAX_N];
    let (mut root, mut count) = (-1i32, 0usize);
    let mut at = 2usize;
    for _ in 0..n {
        let x = *input.add(at); let y = *input.add(at + 1); let label = *input.add(at + 2); at += 3;
        if x < 0 || x >= X_DOMAIN as i64 || y < -64 || y > 63 || label < 0 || label >= MAX_N as i64 { return -1; }
        if seen_x[x as usize] || seen_label[label as usize] { return -1; }
        seen_x[x as usize] = true; seen_label[label as usize] = true;
        let (mut px, mut py, mut pl) = (x, y, label);
        if root < 0 {
            root = count as i32; count += 1;
            let r = root as usize;
            nx[r] = px; ny[r] = py; nl[r] = pl; nlo[r] = 0; nhi[r] = X_DOMAIN as i64;
        } else {
            let (mut cur, mut low, mut high) = (root as usize, 0usize, X_DOMAIN);
            loop {
                if py < ny[cur] { std::mem::swap(&mut px, &mut nx[cur]); std::mem::swap(&mut py, &mut ny[cur]); std::mem::swap(&mut pl, &mut nl[cur]); }
                let mid = (low + high) / 2;
                if px < mid as i64 {
                    if left[cur] < 0 {
                        let child = count; count += 1; left[cur] = child as i32;
                        nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = low as i64; nhi[child] = mid as i64; break;
                    }
                    cur = left[cur] as usize; high = mid;
                } else {
                    if right[cur] < 0 {
                        let child = count; count += 1; right[cur] = child as i32;
                        nx[child] = px; ny[child] = py; nl[child] = pl; nlo[child] = mid as i64; nhi[child] = high as i64; break;
                    }
                    cur = right[cur] as usize; low = mid;
                }
            }
        }
    }
    let mut qx0 = [0i64; MAX_Q]; let mut qx1 = [0i64; MAX_Q]; let mut qy1 = [0i64; MAX_Q];
    for qi in 0..q {
        let x0 = *input.add(at); let x1 = *input.add(at + 1); let y1 = *input.add(at + 2); at += 3;
        if x0 < 0 || x0 > x1 || x1 >= X_DOMAIN as i64 || y1 < -64 || y1 > 63 { return -1; }
        qx0[qi] = x0; qx1[qi] = x1; qy1[qi] = y1;
    }
    let mut result = 0i64;
    for qi in 0..q {
        let mut mask = 0i64;
        if root >= 0 {
            let mut stack = [0usize; MAX_N]; let mut top = 1usize; stack[0] = root as usize;
            while top > 0 {
                top -= 1; let node = stack[top];
                if qx1[qi] < nlo[node] || qx0[qi] >= nhi[node] || ny[node] > qy1[qi] { continue; }
                if qx0[qi] <= nx[node] && nx[node] <= qx1[qi] { mask |= 1i64 << nl[node]; }
                if left[node] >= 0 { stack[top] = left[node] as usize; top += 1; }
                if right[node] >= 0 { stack[top] = right[node] as usize; top += 1; }
            }
        }
        result |= mask << (8 * qi);
    }
    result
}
