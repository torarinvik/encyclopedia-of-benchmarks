#[no_mangle]
pub extern "C" fn paint_house_iii(input: *const i64, length: usize) -> i64 {
    const INF: i64 = 801;
    if input.is_null() || length < 3 || length > 44 {
        return -1;
    }
    let packed = unsafe { std::slice::from_raw_parts(input, length) };
    let (m_value, n_value, target_value) = (packed[0], packed[1], packed[2]);
    if !(1..=8).contains(&m_value) || !(1..=4).contains(&n_value)
        || target_value < 1 || target_value > m_value
    {
        return -1;
    }
    let (m, n, target) = (m_value as usize, n_value as usize, target_value as usize);
    if length != 3 + m + m * n {
        return -1;
    }
    let houses_at = 3;
    let costs_at = 3 + m;
    for house in 0..m {
        if packed[houses_at + house] < 0 || packed[houses_at + house] > n_value {
            return -1;
        }
    }
    for cost in 0..m * n {
        if !(0..=100).contains(&packed[costs_at + cost]) {
            return -1;
        }
    }
    let at = |color: usize, groups: usize| color * 9 + groups;
    let mut previous = [INF; 45];
    let mut current = [INF; 45];
    let first = packed[houses_at];
    for color in 1..=n {
        if first == 0 || first == color as i64 {
            previous[at(color, 1)] = if first == 0 { packed[costs_at + color - 1] } else { 0 };
        }
    }
    for house in 1..m {
        current.fill(INF);
        let fixed = packed[houses_at + house];
        for color in 1..=n {
            if fixed != 0 && fixed != color as i64 {
                continue;
            }
            let paint_cost = if fixed == 0 { packed[costs_at + house * n + color - 1] } else { 0 };
            for groups in 1..=target {
                let mut best = INF;
                for old_color in 1..=n {
                    let old_groups = groups - if old_color != color { 1 } else { 0 };
                    if old_groups >= 1 {
                        best = best.min(previous[at(old_color, old_groups)]);
                    }
                }
                if best < INF {
                    current[at(color, groups)] = best + paint_cost;
                }
            }
        }
        previous = current;
    }
    let answer = (1..=n).map(|color| previous[at(color, target)]).min().unwrap_or(INF);
    if answer >= INF { -1 } else { answer }
}
