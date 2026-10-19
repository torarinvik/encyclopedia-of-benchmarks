const MAX_N: i64 = 15;

#[no_mangle]
pub extern "C" fn nestedloop(input: i64) -> i64 {
    if input < 0 || input > MAX_N { return -1; }
    let n = input as i32;
    let mut x: i32 = 0;
    for _a in 0..n {
        for _b in 0..n {
            for _c in 0..n {
                for _d in 0..n {
                    for _e in 0..n {
                        for _f in 0..n {
                            x += 1;
                        }
                    }
                }
            }
        }
    }
    i64::from(x)
}
