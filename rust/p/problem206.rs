const START: i64 = 138_902_663;
const MINIMUM: i64 = 101_010_103;

fn is_square_form(mut value: i64) -> bool {
    let mut digit = 9;
    while value > 0 {
        if value % 10 != digit { return false; }
        value /= 100;
        digit -= 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn problem206(unused: i64) -> i64 {
    if unused != 0 { return -1; }
    let mut candidate = START;
    while candidate >= MINIMUM {
        if is_square_form(candidate * candidate) { return candidate * 10; }
        candidate -= if candidate % 10 == 3 { 6 } else { 4 };
    }
    -1
}
