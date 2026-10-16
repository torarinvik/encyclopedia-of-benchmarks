fn question_function(n: i64) -> i64 {
    let mut term = 1_i64;
    let mut total = 0_i64;
    for exponent in 0..=10 {
        if exponent % 2 == 0 { total += term; } else { total -= term; }
        term *= n;
    }
    total
}

#[no_mangle]
pub extern "C" fn problem101(order: i64) -> i64 {
    if order > 10 { return -1; }
    if order <= 0 { return 0; }
    let order = order as usize;
    let mut data = [0_i64; 10];
    for i in 0..order { data[i] = question_function((i + 1) as i64); }
    let mut total_fit = 0_i64;
    for k in 1..=order {
        let mut row = [0_i64; 10];
        let mut differences = [0_i64; 10];
        row[..k].copy_from_slice(&data[..k]);
        differences[0] = row[0];
        for level in 1..k {
            for i in 0..(k - level) { row[i] = row[i + 1] - row[i]; }
            differences[level] = row[0];
        }
        let mut x = 1_i64;
        loop {
            let mut prediction = 0_i64;
            let mut choose = 1_i64;
            for j in 0..k {
                prediction += differences[j] * choose;
                if j + 1 < k { choose = choose * (x - 1 - j as i64) / (j + 1) as i64; }
            }
            if prediction != question_function(x) { total_fit += prediction; break; }
            x += 1;
        }
    }
    total_fit
}
