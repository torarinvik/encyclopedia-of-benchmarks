#[derive(Clone, Copy)]
struct Fraction { numerator: i64, denominator: i64 }

fn same_division(v: &[i64], order: &[usize]) -> bool {
    let first = 1 + 12 * order[0];
    (1..order.len()).all(|p| {
        let current = 1 + 12 * order[p];
        v[first + 1] == v[current + 1] && v[first + 2] == v[current + 2]
    })
}

fn score_for(v: &[i64], n: usize, order: &[usize], team: usize, stage: usize, same_div: bool) -> Fraction {
    if stage == 0 {
        let cells = n * n;
        let wins_start = 1 + 12 * n;
        let ties_start = wins_start + cells;
        let (mut won, mut lost, mut tied) = (0i64, 0i64, 0i64);
        for &other in order {
            if other == team { continue; }
            won += v[wins_start + team * n + other];
            lost += v[wins_start + other * n + team];
            tied += v[ties_start + team * n + other];
        }
        let games = won + lost + tied;
        return Fraction { numerator: 2 * won + tied, denominator: if games == 0 { 1 } else { 2 * games } };
    }
    let base = 1 + 12 * team;
    match stage {
        1 | 2 | 3 => {
            let field = if stage == 1 { 3 } else if stage == 2 { 5 } else { 7 };
            let games = v[base + field + 1];
            Fraction { numerator: v[base + field], denominator: if games == 0 { 1 } else { 2 * games } }
        }
        4 => Fraction { numerator: v[base + if same_div { 9 } else { 10 }], denominator: 1 },
        _ => Fraction { numerator: v[base + 11], denominator: 1 },
    }
}

fn compare(a: Fraction, b: Fraction) -> std::cmp::Ordering {
    (a.numerator * b.denominator).cmp(&(b.numerator * a.denominator))
}

fn refine(v: &[i64], n: usize, order: &mut [usize], stage: usize, same_div: bool) {
    for i in 1..order.len() {
        let item = order[i];
        let item_score = score_for(v, n, order, item, stage, same_div);
        let mut j = i;
        while j > 0 {
            let previous = score_for(v, n, order, order[j - 1], stage, same_div);
            if compare(item_score, previous) != std::cmp::Ordering::Greater { break; }
            order[j] = order[j - 1];
            j -= 1;
        }
        order[j] = item;
    }
    let best = score_for(v, n, order, order[0], stage, same_div);
    if (1..order.len()).all(|i| compare(best, score_for(v, n, order, order[i], stage, same_div)) == std::cmp::Ordering::Equal) {
        resolve(v, n, order, stage + 1);
        return;
    }
    let mut start = 0;
    while start < order.len() {
        let score = score_for(v, n, order, order[start], stage, same_div);
        let mut end = start + 1;
        while end < order.len() && compare(score, score_for(v, n, order, order[end], stage, same_div)) == std::cmp::Ordering::Equal { end += 1; }
        resolve(v, n, &mut order[start..end], 0);
        start = end;
    }
}

fn sweep_result(v: &[i64], n: usize, order: &[usize]) -> Option<(bool, usize)> {
    let cells = n * n;
    let wins_start = 1 + 12 * n;
    let ties_start = wins_start + cells;
    for position in 0..order.len() {
        let team = order[position];
        let (mut win, mut lose) = (true, true);
        for &other in order {
            if other == team { continue; }
            let won = v[wins_start + team * n + other];
            let lost = v[wins_start + other * n + team];
            let tied = v[ties_start + team * n + other];
            if won + lost + tied == 0 || tied != 0 { win = false; lose = false; }
            if lost != 0 { win = false; }
            if won != 0 { lose = false; }
        }
        if win { return Some((true, position)); }
        if lose { return Some((false, position)); }
    }
    None
}

fn resolve(v: &[i64], n: usize, order: &mut [usize], stage: usize) {
    if order.len() <= 1 || stage >= 6 { return; }
    let same_div = same_division(v, order);
    if stage == 0 {
        if same_div || order.len() == 2 {
            refine(v, n, order, 0, same_div);
            return;
        }
        if let Some((winner, position)) = sweep_result(v, n, order) {
            if winner {
                order.swap(0, position);
                resolve(v, n, &mut order[1..], 0);
            } else {
                let last = order.len() - 1;
                order.swap(last, position);
                resolve(v, n, &mut order[..last], 0);
            }
            return;
        }
        resolve(v, n, order, 1);
        return;
    }
    if stage == 1 && !same_div { resolve(v, n, order, 2); return; }
    if stage == 3 && order.iter().any(|&i| v[1 + 12 * i + 8] < 4) {
        resolve(v, n, order, 4);
        return;
    }
    refine(v, n, order, stage, same_div);
}

#[no_mangle]
pub unsafe extern "C" fn prolangs_football_tiebreaks(values: *const i64, length: usize) -> i64 {
    if values.is_null() || length < 1 { return -2; }
    let v = std::slice::from_raw_parts(values, length);
    if !(2..=8).contains(&v[0]) { return -2; }
    let n = v[0] as usize;
    let cells = n * n;
    if length != 1 + 12 * n + 2 * cells { return -2; }
    let mut ids = Vec::with_capacity(n);
    for team in 0..n {
        let base = 1 + 12 * team;
        let id = v[base];
        if !(0..=31).contains(&id) || !(0..=1).contains(&v[base + 1]) || !(0..=2).contains(&v[base + 2]) { return -2; }
        for field in [3usize, 5, 7] {
            let points = v[base + field];
            let games = v[base + field + 1];
            if !(0..=64).contains(&games) || points < 0 || points > 2 * games { return -2; }
        }
        if (9..=11).any(|field| v[base + field] < -4096 || v[base + field] > 4096) { return -2; }
        if ids.iter().any(|&previous| previous == id) { return -2; }
        ids.push(id);
    }
    let wins_start = 1 + 12 * n;
    let ties_start = wins_start + cells;
    for i in 0..n { for j in 0..n {
        let wins = v[wins_start + i * n + j];
        let ties = v[ties_start + i * n + j];
        if !(0..=64).contains(&wins) || !(0..=64).contains(&ties) ||
            (i == j && (wins != 0 || ties != 0)) || ties != v[ties_start + j * n + i] { return -2; }
    }}

    let mut order: Vec<usize> = (0..n).collect();
    order.sort_by_key(|&i| (v[1 + 12 * i + 1], ids[i]));
    resolve(v, n, &mut order, 0);

    let mut result = 0i64;
    for index in order { result = result * 32 + ids[index]; }
    result
}
