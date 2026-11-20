module ruf_schobel_set_cover;

const usz MAX_ROWS = 6;
const usz MAX_COLUMNS = 8;
const usz MAX_INPUT = 17;
const usz MAX_STACK = 32;

fn void store_i64_le(uint8* output, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[byte] = (uint8)(bits & 255); bits >>= 8; }
}

fn bool interval_cover(long* left, long* right, usz count, long* weights, usz columns,
                       long* out_cost, long* out_mask) {
    if (count == 0) { out_cost[0] = 0; out_mask[0] = 0; return true; }
    long minimum_right = right[0], maximum_left = left[0];
    for (usz i = 1; i < count; i += 1) {
        if (right[i] < minimum_right) minimum_right = right[i];
        if (left[i] > maximum_left) maximum_left = left[i];
    }
    long[MAX_COLUMNS] costs = zeroed, masks = zeroed;
    for (usz point = 0; point < columns; point += 1) costs[point] = 1000000;
    for (usz point = 0; point < columns; point += 1) {
        if (point.long() <= minimum_right) { costs[point] = weights[point]; masks[point] = 1l << point; }
        for (usz previous = 0; previous < point; previous += 1) {
            if (costs[previous] == 1000000) continue;
            bool blocked = false;
            for (usz i = 0; i < count; i += 1)
                if (previous.long() < left[i] && right[i] < point.long()) { blocked = true; break; }
            if (blocked) continue;
            long candidate_cost = costs[previous] + weights[point];
            long candidate_mask = masks[previous] | (1l << point);
            if (candidate_cost < costs[point] ||
                (candidate_cost == costs[point] && candidate_mask < masks[point])) {
                costs[point] = candidate_cost; masks[point] = candidate_mask;
            }
        }
    }
    long best_cost = 1000000, best_mask = 0;
    for (usz point = maximum_left.usz(); point < columns; point += 1) {
        if (costs[point] < best_cost ||
            (costs[point] == best_cost && costs[point] != 1000000 && masks[point] < best_mask)) {
            best_cost = costs[point]; best_mask = masks[point];
        }
    }
    if (best_cost == 1000000) return false;
    out_cost[0] = best_cost; out_mask[0] = best_mask;
    return true;
}

fn long ruf_schobel_set_cover(long* input, usz length, uint8* output, usz capacity)
        @export("ruf_schobel_set_cover") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long rows_raw = input[0], columns_raw = input[1];
    if (rows_raw < 1 || rows_raw > MAX_ROWS.long() || columns_raw < 1 || columns_raw > MAX_COLUMNS.long() ||
        length != 2 + rows_raw.usz() + columns_raw.usz()) return -1;
    usz rows = rows_raw.usz(), columns = columns_raw.usz();
    long[MAX_COLUMNS] weights = zeroed;
    for (usz col = 0; col < columns; col += 1) {
        if (input[2 + col] < 1 || input[2 + col] > 20) return -1;
        weights[col] = input[2 + col];
    }
    ulong allowed = (1ul << columns) - 1;
    ulong[MAX_ROWS] row_masks = zeroed;
    long[MAX_ROWS][MAX_COLUMNS] block_left = zeroed, block_right = zeroed;
    long[MAX_ROWS] block_count = zeroed;
    for (usz row = 0; row < rows; row += 1) {
        long raw = input[2 + columns + row];
        if (raw < 0 || ((ulong)raw & ~allowed) != 0) return -1;
        row_masks[row] = (ulong)raw;
        usz col = 0;
        while (col < columns) {
            if ((row_masks[row] & (1ul << col)) == 0) { col += 1; continue; }
            usz block = block_count[row].usz();
            block_left[row][block] = col.long();
            while (col + 1 < columns && (row_masks[row] & (1ul << (col + 1))) != 0) col += 1;
            block_right[row][block] = col.long();
            block_count[row] += 1;
            col += 1;
        }
    }
    for (usz row = 0; row < rows; row += 1) {
        if row_masks[row] == 0 {
            if (output == null || capacity < 8) return -2;
            store_i64_le(output, -1);
            return 8;
        }
    }
    long best_cost = 1000000;
    long[MAX_STACK][MAX_ROWS] stack = zeroed;
    long stack_size = 1;
    for (usz row = 0; row < rows; row += 1) stack[0][row] = -1;
    while (stack_size > 0) {
        stack_size -= 1;
        long[MAX_ROWS] fixed = zeroed;
        for (usz row = 0; row < rows; row += 1) fixed[row] = stack[stack_size.usz()][row];
        long[MAX_ROWS] left = zeroed, right = zeroed;
        usz count = 0;
        for (usz row = 0; row < rows; row += 1) {
            if (block_count[row] == 1 || fixed[row] >= 0) {
                usz block = 0;
                if (block_count[row] != 1) block = fixed[row].usz();
                left[count] = block_left[row][block]; right[count] = block_right[row][block]; count += 1;
            }
        }
        long lower_cost = 0, lower_mask = 0;
        if (!interval_cover(&left[0], &right[0], count, &weights[0], columns, &lower_cost, &lower_mask)) continue;
        long[MAX_ROWS] extra_left = zeroed, extra_right = zeroed;
        usz extra_count = 0;
        for (usz row = 0; row < rows; row += 1) {
            if ((row_masks[row] & lower_mask.ul()) != 0) continue;
            usz chosen = 0;
            long chosen_cost = 1000000;
            for (usz block = 0; block < block_count[row].usz(); block += 1) {
                long cheapest = 1000000;
                for (usz col = block_left[row][block].usz(); col <= block_right[row][block].usz(); col += 1)
                    if (weights[col] < cheapest) cheapest = weights[col];
                if (cheapest < chosen_cost) { chosen_cost = cheapest; chosen = block; }
            }
            extra_left[extra_count] = block_left[row][chosen]; extra_right[extra_count] = block_right[row][chosen]; extra_count += 1;
        }
        long extra_cost = 0, extra_mask = 0;
        if (!interval_cover(&extra_left[0], &extra_right[0], extra_count, &weights[0], columns,
                            &extra_cost, &extra_mask)) continue;
        long candidate_mask = lower_mask | extra_mask, candidate_cost = 0;
        for (usz col = 0; col < columns; col += 1)
            if ((candidate_mask & (1l << col)) != 0) candidate_cost += weights[col];
        if (candidate_cost < best_cost) best_cost = candidate_cost;
        if (best_cost <= lower_cost) continue;
        long branch = -1;
        for (usz row = 0; row < rows; row += 1)
            if (block_count[row] > 1 && fixed[row] < 0) { branch = row.long(); break; }
        if (branch < 0) continue;
        for (long block = block_count[branch.usz()] - 1; block >= 0; block -= 1) {
            for (usz row = 0; row < rows; row += 1) stack[stack_size.usz()][row] = fixed[row];
            stack[stack_size.usz()][branch.usz()] = block;
            stack_size += 1;
        }
    }
    long result = best_cost;
    if (best_cost == 1000000) result = -1;
    if (output == null || capacity < 8) return -2;
    store_i64_le(output, result);
    return 8;
}
