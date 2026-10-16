/// Preserve the Go source's direct square-and-last-digit loop.
#[no_mangle]
pub extern "C" fn isautomorphic(n: i64) -> i64 {
    const MAX_SAFE: i64 = 3_037_000_499;
    if n < -MAX_SAFE || n > MAX_SAFE {
        return -1;
    }
    if n < 0 {
        return 0;
    }

    let mut square = n * n;
    let mut remaining = n;
    while remaining > 0 {
        if remaining % 10 != square % 10 {
            return 0;
        }
        remaining /= 10;
        square /= 10;
    }
    1
}
