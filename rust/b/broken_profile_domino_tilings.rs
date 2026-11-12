const MAX_STATES: usize = 256;
const MODULUS: i64 = 998_244_353;

#[no_mangle]
pub unsafe extern "C" fn broken_profile_domino_tilings(input: *const i64, length: usize) -> i64 {
    if input.is_null() || length != 2 { return -1; }
    let v = std::slice::from_raw_parts(input, length);
    let (h0, w0) = (v[0], v[1]);
    if h0 < 1 || h0 > 64 || w0 < 1 || w0 > 64 || h0.min(w0) > 8 || h0 * w0 > 512 { return -1; }
    let height = h0.max(w0) as usize;
    let width = h0.min(w0) as usize;
    let states = 1usize << width;
    let full = states - 1;
    let mut dp = [0i64; MAX_STATES];
    let mut next = [0i64; MAX_STATES];
    dp[0] = 1;
    for row in 0..height {
        next.fill(0);
        for incoming in 0..states {
            if dp[incoming] == 0 { continue; }
            for outgoing in 0..states {
                if incoming & outgoing != 0 || row + 1 == height && outgoing != 0 { continue; }
                let free = full & !(incoming | outgoing);
                let mut col = 0usize;
                let mut valid = true;
                while col < width {
                    if free & (1 << col) != 0 {
                        if col + 1 >= width || free & (1 << (col + 1)) == 0 { valid = false; break; }
                        col += 2;
                    } else { col += 1; }
                }
                if valid { next[outgoing] = (next[outgoing] + dp[incoming]) % MODULUS; }
            }
        }
        dp = next;
    }
    dp[0]
}
