#[no_mangle]
pub extern "C" fn golombs_sequence(index: i64) -> i64 {
    if !(0..=64).contains(&index) {
        return -1;
    }
    if index == 0 {
        return 1;
    }
    if index <= 2 {
        return 2;
    }
    let mut queue = [0i64; 65];
    queue[0] = 2;
    let mut head = 0usize;
    let mut tail = 1usize;
    let mut generated = 3i64;
    let mut value = 3i64;
    while generated <= index {
        let repetitions = queue[head];
        head += 1;
        let mut repeated = 0i64;
        while repeated < repetitions && generated <= index {
            queue[tail] = value;
            tail += 1;
            if generated == index {
                return value;
            }
            generated += 1;
            repeated += 1;
        }
        value += 1;
    }
    -1
}
