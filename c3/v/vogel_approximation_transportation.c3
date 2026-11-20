module vogel_approximation_transportation;

const usz MAX_LENGTH = 18;

fn long vogel_approximation_transportation(long* input, usz length) @export("vogel_approximation_transportation") {
    if (input == null || length < 5 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > 3 || input[1] < 1 || input[1] > 3) return -1;
    usz rows = (usz)input[0];
    usz cols = (usz)input[1];
    usz cell_count = rows * cols;
    if (length != 2 + cell_count + rows + cols) return -1;

    long[9] costs = {};
    long[3] supply = {};
    long[3] demand = {};
    usz offset = 2;
    for (usz i = 0; i < cell_count; i += 1) {
        long value = input[offset + i];
        if (value < 0 || value > 9) return -1;
        costs[i] = value;
    }
    offset += cell_count;
    long supply_total = 0, demand_total = 0;
    for (usz i = 0; i < rows; i += 1) {
        long value = input[offset + i];
        if (value < 1 || value > 3) return -1;
        supply[i] = value; supply_total += value;
    }
    offset += rows;
    for (usz j = 0; j < cols; j += 1) {
        long value = input[offset + j];
        if (value < 1 || value > 3) return -1;
        demand[j] = value; demand_total += value;
    }
    if (supply_total != demand_total) return -1;

    bool[3] active_rows = {true, true, true};
    bool[3] active_cols = {true, true, true};
    long[9] allocation = {};
    long total_cost = 0;
    long remaining = supply_total;
    while (remaining > 0) {
        int best_kind = -1;
        usz best_line = 0;
        long best_penalty = -1;
        for (int kind = 0; kind < 2; kind += 1) {
            usz line_count = kind == 0 ? rows : cols;
            usz partner_count = kind == 0 ? cols : rows;
            for (usz line = 0; line < line_count; line += 1) {
                if (!(kind == 0 ? active_rows[line] : active_cols[line])) continue;
                long first = 10, second = 10;
                usz found = 0;
                for (usz partner = 0; partner < partner_count; partner += 1) {
                    if (!(kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
                    usz row = kind == 0 ? line : partner;
                    usz col = kind == 0 ? partner : line;
                    long value = costs[row * cols + col];
                    if (value < first) { second = first; first = value; }
                    else if (value < second) { second = value; }
                    found += 1;
                }
                if (found == 0) continue;
                long penalty = found == 1 ? 10 : second - first;
                if (penalty > best_penalty) {
                    best_penalty = penalty; best_kind = kind; best_line = line;
                }
            }
        }
        if (best_kind < 0) return -1;
        usz partner_count = best_kind == 0 ? cols : rows;
        usz best_partner = partner_count;
        long cheapest = 10;
        for (usz partner = 0; partner < partner_count; partner += 1) {
            if (!(best_kind == 0 ? active_cols[partner] : active_rows[partner])) continue;
            usz row = best_kind == 0 ? best_line : partner;
            usz col = best_kind == 0 ? partner : best_line;
            long value = costs[row * cols + col];
            if (value < cheapest) { cheapest = value; best_partner = partner; }
        }
        if (best_partner == partner_count) return -1;
        usz row = best_kind == 0 ? best_line : best_partner;
        usz col = best_kind == 0 ? best_partner : best_line;
        long quantity = supply[row] < demand[col] ? supply[row] : demand[col];
        allocation[row * 3 + col] = quantity;
        total_cost += quantity * costs[row * cols + col];
        supply[row] -= quantity; demand[col] -= quantity; remaining -= quantity;
        if (supply[row] == 0) active_rows[row] = false;
        if (demand[col] == 0) active_cols[col] = false;
    }

    long signature = 0, place = 1;
    for (usz cell = 0; cell < 9; cell += 1) {
        signature += allocation[cell] * place;
        place *= 4;
    }
    return total_cost * place + signature;
}
