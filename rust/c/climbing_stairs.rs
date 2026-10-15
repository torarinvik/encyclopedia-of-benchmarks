/// Count ways to climb n stairs using one or two steps per move.
#[no_mangle]
pub extern "C" fn climbing_stairs(steps: i64) -> i64 {
    if !(1..=45).contains(&steps) { return -1; }
    let mut previous = 1i64;
    let mut current = 1i64;
    for _ in 2..=steps {
        let next = previous + current;
        previous = current;
        current = next;
    }
    current
}
