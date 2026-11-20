export fn vogel_approximation_transportation(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 5 or length > 18) return -1;
    if (input[0] < 1 or input[0] > 3 or input[1] < 1 or input[1] > 3) return -1;
    const rows: usize = @intCast(input[0]);
    const cols: usize = @intCast(input[1]);
    const cell_count = rows * cols;
    if (length != 2 + cell_count + rows + cols) return -1;
    var costs: [9]i64 = @splat(0);
    var supply: [3]i64 = @splat(0);
    var demand: [3]i64 = @splat(0);
    var offset: usize = 2;
    for (0..cell_count) |i| {
        const value = input[offset + i];
        if (value < 0 or value > 9) return -1;
        costs[i] = value;
    }
    offset += cell_count;
    var supply_total: i64 = 0;
    var demand_total: i64 = 0;
    for (0..rows) |i| {
        const value = input[offset + i];
        if (value < 1 or value > 3) return -1;
        supply[i] = value; supply_total += value;
    }
    offset += rows;
    for (0..cols) |j| {
        const value = input[offset + j];
        if (value < 1 or value > 3) return -1;
        demand[j] = value; demand_total += value;
    }
    if (supply_total != demand_total) return -1;

    var active_rows: [3]bool = @splat(true);
    var active_cols: [3]bool = @splat(true);
    var allocation: [9]i64 = @splat(0);
    var total_cost: i64 = 0;
    var remaining = supply_total;
    while (remaining > 0) {
        var best_kind: i32 = -1;
        var best_line: usize = 0;
        var best_penalty: i64 = -1;
        for (0..2) |kind| {
            const line_count = if (kind == 0) rows else cols;
            const partner_count = if (kind == 0) cols else rows;
            for (0..line_count) |line| {
                if (!(if (kind == 0) active_rows[line] else active_cols[line])) continue;
                var first: i64 = 10;
                var second: i64 = 10;
                var found: usize = 0;
                for (0..partner_count) |partner| {
                    if (!(if (kind == 0) active_cols[partner] else active_rows[partner])) continue;
                    const row = if (kind == 0) line else partner;
                    const col = if (kind == 0) partner else line;
                    const value = costs[row * cols + col];
                    if (value < first) { second = first; first = value; }
                    else if (value < second) { second = value; }
                    found += 1;
                }
                if (found == 0) continue;
                const penalty: i64 = if (found == 1) 10 else second - first;
                if (penalty > best_penalty) { best_penalty = penalty; best_kind = @intCast(kind); best_line = line; }
            }
        }
        if (best_kind < 0) return -1;
        const partner_count = if (best_kind == 0) cols else rows;
        var best_partner = partner_count;
        var cheapest: i64 = 10;
        for (0..partner_count) |partner| {
            if (!(if (best_kind == 0) active_cols[partner] else active_rows[partner])) continue;
            const row = if (best_kind == 0) best_line else partner;
            const col = if (best_kind == 0) partner else best_line;
            const value = costs[row * cols + col];
            if (value < cheapest) { cheapest = value; best_partner = partner; }
        }
        if (best_partner == partner_count) return -1;
        const row = if (best_kind == 0) best_line else best_partner;
        const col = if (best_kind == 0) best_partner else best_line;
        const amount = @min(supply[row], demand[col]);
        allocation[row * 3 + col] = amount;
        total_cost += amount * costs[row * cols + col];
        supply[row] -= amount; demand[col] -= amount; remaining -= amount;
        if (supply[row] == 0) active_rows[row] = false;
        if (demand[col] == 0) active_cols[col] = false;
    }
    var signature: i64 = 0;
    var place: i64 = 1;
    for (allocation) |amount| { signature += amount * place; place *= 4; }
    return total_cost * 262144 + signature;
}
