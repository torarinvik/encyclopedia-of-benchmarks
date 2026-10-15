const MAX_INDEX: i64 = 3_810_777;

#[no_mangle]
pub extern "C" fn tetrahedral_sequence(index: i64) -> i64 {
    if index < 0 || index > MAX_INDEX {
        return -1;
    }
    let mut a = index;
    let mut b = index + 1;
    let mut c = index + 2;
    if a % 2 == 0 { a /= 2; }
    else if b % 2 == 0 { b /= 2; }
    else { c /= 2; }
    if a % 3 == 0 { a /= 3; }
    else if b % 3 == 0 { b /= 3; }
    else { c /= 3; }
    a * b * c
}
