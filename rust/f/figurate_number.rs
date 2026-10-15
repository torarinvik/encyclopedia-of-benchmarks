/// Pack triangular, tetrahedral, and pentatope membership bits.
fn is_triangular(n: i64) -> bool {
    let mut i = 0i64;
    while i <= n {
        let term = i * (i + 1) / 2;
        if term == n { return true; }
        if term > n { return false; }
        i += 1;
    }
    false
}

fn is_tetrahedral(n: i64) -> bool {
    let mut i = 1i64;
    while i <= n {
        let term = i * (i + 1) * (i + 2) / 6;
        if term == n { return true; }
        if term > n { return false; }
        i += 1;
    }
    false
}

fn is_pentatope(n: i64) -> bool {
    let mut i = 1i64;
    while i <= n {
        let term = i * (i + 1) * (i + 2) * (i + 3) / 24;
        if term == n { return true; }
        if term > n { return false; }
        i += 1;
    }
    false
}

#[no_mangle]
pub extern "C" fn figurate_number(n: i64) -> i64 {
    if n < 0 || n > 1_000_000 { return -1; }
    (if is_triangular(n) { 1 } else { 0 })
        + (if is_tetrahedral(n) { 2 } else { 0 })
        + (if is_pentatope(n) { 4 } else { 0 })
}
