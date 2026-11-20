#[no_mangle]
pub unsafe extern "C" fn vogel_approximation_transportation(input: *const i64, length: usize) -> i64 {
    if input.is_null() || !(5..=18).contains(&length) { return -1; }
    let r0 = *input;
    let c0 = *input.add(1);
    if !(1..=3).contains(&r0) || !(1..=3).contains(&c0) { return -1; }
    let rows = r0 as usize;
    let cols = c0 as usize;
    let cell_count = rows * cols;
    if length != 2 + cell_count + rows + cols { return -1; }
    let mut costs = [0i64; 9];
    let mut supply = [0i64; 3];
    let mut demand = [0i64; 3];
    let mut offset = 2;
    for i in 0..cell_count {
        let value = *input.add(offset + i);
        if !(0..=9).contains(&value) { return -1; }
        costs[i] = value;
    }
    offset += cell_count;
    let mut supply_total = 0;
    let mut demand_total = 0;
    for i in 0..rows {
        let value = *input.add(offset + i);
        if !(1..=3).contains(&value) { return -1; }
        supply[i] = value; supply_total += value;
    }
    offset += rows;
    for j in 0..cols {
        let value = *input.add(offset + j);
        if !(1..=3).contains(&value) { return -1; }
        demand[j] = value; demand_total += value;
    }
    if supply_total != demand_total { return -1; }

    let mut active_rows = [true; 3];
    let mut active_cols = [true; 3];
    let mut allocation = [0i64; 9];
    let mut total_cost = 0i64;
    let mut remaining = supply_total;
    while remaining > 0 {
        let mut best_kind = -1i32;
        let mut best_line = 0usize;
        let mut best_penalty = -1i64;
        for kind in 0..2 {
            let line_count = if kind == 0 { rows } else { cols };
            let partner_count = if kind == 0 { cols } else { rows };
            for line in 0..line_count {
                if !(if kind == 0 { active_rows[line] } else { active_cols[line] }) { continue; }
                let mut first = 10i64;
                let mut second = 10i64;
                let mut count = 0usize;
                for partner in 0..partner_count {
                    if !(if kind == 0 { active_cols[partner] } else { active_rows[partner] }) { continue; }
                    let row = if kind == 0 { line } else { partner };
                    let col = if kind == 0 { partner } else { line };
                    let value = costs[row * cols + col];
                    if value < first { second = first; first = value; }
                    else if value < second { second = value; }
                    count += 1;
                }
                if count == 0 { continue; }
                let penalty = if count == 1 { 10 } else { second - first };
                if penalty > best_penalty { best_penalty = penalty; best_kind = kind; best_line = line; }
            }
        }
        if best_kind < 0 { return -1; }
        let partner_count = if best_kind == 0 { cols } else { rows };
        let mut best_partner = partner_count;
        let mut cheapest = 10i64;
        for partner in 0..partner_count {
            if !(if best_kind == 0 { active_cols[partner] } else { active_rows[partner] }) { continue; }
            let row = if best_kind == 0 { best_line } else { partner };
            let col = if best_kind == 0 { partner } else { best_line };
            let value = costs[row * cols + col];
            if value < cheapest { cheapest = value; best_partner = partner; }
        }
        if best_partner == partner_count { return -1; }
        let row = if best_kind == 0 { best_line } else { best_partner };
        let col = if best_kind == 0 { best_partner } else { best_line };
        let amount = supply[row].min(demand[col]);
        allocation[row * 3 + col] = amount;
        total_cost += amount * costs[row * cols + col];
        supply[row] -= amount; demand[col] -= amount; remaining -= amount;
        if supply[row] == 0 { active_rows[row] = false; }
        if demand[col] == 0 { active_cols[col] = false; }
    }
    let mut signature = 0i64;
    let mut place = 1i64;
    for amount in allocation { signature += amount * place; place *= 4; }
    total_cost * 262144 + signature
}
