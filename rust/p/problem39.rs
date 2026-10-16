fn integer_sqrt(value: i64) -> i64 {
    let mut low = 0i64;
    let mut high = 1415i64;
    while high - low > 1 {
        let middle = (low + high) / 2;
        if middle * middle <= value { low = middle; }
        else { high = middle; }
    }
    low
}

#[no_mangle]
pub extern "C" fn problem39(limit: i64) -> i64 {
    if !(12..=1000).contains(&limit) { return -1; }
    let mut counts = [0i64; 1001];
    let mut first_order = [0i64; 1001];
    let mut next_order = 1i64;
    for base in 1..=limit {
        for perpendicular in base..=limit {
            let square_sum = base * base + perpendicular * perpendicular;
            let hypotenuse = integer_sqrt(square_sum);
            if hypotenuse * hypotenuse != square_sum { continue; }
            let perimeter = base + perpendicular + hypotenuse;
            if perimeter > limit { continue; }
            let index = perimeter as usize;
            if counts[index] == 0 {
                first_order[index] = next_order;
                next_order += 1;
            }
            counts[index] += 1;
        }
    }
    let mut best_perimeter = -1i64;
    let mut best_count = 0i64;
    let mut best_order = i64::MAX;
    for perimeter in 1..=limit {
        let index = perimeter as usize;
        if counts[index] > 0 && (counts[index] > best_count ||
            (counts[index] == best_count && first_order[index] < best_order)) {
            best_perimeter = perimeter;
            best_count = counts[index];
            best_order = first_order[index];
        }
    }
    best_perimeter
}
