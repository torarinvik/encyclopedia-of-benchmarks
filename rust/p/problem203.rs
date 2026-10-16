fn is_squarefree(number: i64) -> bool {
    let mut copy = number;
    let mut divisor = 2_i64;
    while divisor * divisor <= copy {
        let mut multiplicity = 0;
        while copy % divisor == 0 { copy /= divisor; multiplicity += 1; }
        if multiplicity >= 2 { return false; }
        divisor += 1;
    }
    true
}

#[no_mangle]
pub extern "C" fn problem203(depth: i64) -> i64 {
    if depth > 51 { return -1; }
    let mut row = [0_i64; 51];
    let mut values = [0_i64; 1326];
    row[0] = 1;
    values[0] = 1;
    let mut count = 1_usize;
    let mut row_length = 1_usize;
    for _row_index in 2..=depth {
        row[row_length] = 1;
        let mut col = row_length - 1;
        while col > 0 { row[col] += row[col - 1]; col -= 1; }
        row[0] = 1;
        row_length += 1;
        for col in 0..row_length { values[count] = row[col]; count += 1; }
    }
    for i in 1..count {
        let value = values[i];
        let mut j = i;
        while j > 0 && values[j - 1] > value { values[j] = values[j - 1]; j -= 1; }
        values[j] = value;
    }
    let mut total = 0_i64;
    for i in 0..count {
        if i > 0 && values[i] == values[i - 1] { continue; }
        if is_squarefree(values[i]) { total += values[i]; }
    }
    total
}
