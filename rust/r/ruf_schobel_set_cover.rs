const MAX_ROWS: usize = 6;
const MAX_COLUMNS: usize = 8;
const MAX_INPUT: usize = 17;
const MAX_STACK: usize = 32;

fn interval_cover(
    left: &[usize; MAX_ROWS], right: &[usize; MAX_ROWS], count: usize,
    weights: &[i64; MAX_COLUMNS], columns: usize,
) -> Option<(i64, i64)> {
    if count == 0 { return Some((0, 0)); }
    let mut minimum_right = right[0];
    let mut maximum_left = left[0];
    for i in 1..count {
        minimum_right = minimum_right.min(right[i]);
        maximum_left = maximum_left.max(left[i]);
    }
    let mut costs = [1_000_000i64; MAX_COLUMNS];
    let mut masks = [0i64; MAX_COLUMNS];
    for point in 0..columns {
        if point <= minimum_right {
            costs[point] = weights[point];
            masks[point] = 1i64 << point;
        }
        for previous in 0..point {
            if costs[previous] == 1_000_000 { continue; }
            let mut blocked = false;
            for i in 0..count {
                if previous < left[i] && right[i] < point { blocked = true; break; }
            }
            if blocked { continue; }
            let candidate_cost = costs[previous] + weights[point];
            let candidate_mask = masks[previous] | (1i64 << point);
            if candidate_cost < costs[point]
                || candidate_cost == costs[point] && candidate_mask < masks[point] {
                costs[point] = candidate_cost;
                masks[point] = candidate_mask;
            }
        }
    }
    let mut best: Option<(i64, i64)> = None;
    for point in maximum_left..columns {
        if costs[point] == 1_000_000 { continue; }
        let candidate = (costs[point], masks[point]);
        if best.map_or(true, |current| candidate < current) { best = Some(candidate); }
    }
    best
}

#[no_mangle]
pub unsafe extern "C" fn ruf_schobel_set_cover(
    input: *const i64, length: usize, output: *mut u8, capacity: usize,
) -> i64 {
    if input.is_null() || length < 4 || length > MAX_INPUT { return -1; }
    let rows_raw = *input;
    let columns_raw = *input.add(1);
    if !(1..=MAX_ROWS as i64).contains(&rows_raw)
        || !(1..=MAX_COLUMNS as i64).contains(&columns_raw) { return -1; }
    let rows = rows_raw as usize;
    let columns = columns_raw as usize;
    if length != 2 + rows + columns { return -1; }
    let mut weights = [0i64; MAX_COLUMNS];
    for column in 0..columns {
        let weight = *input.add(2 + column);
        if !(1..=20).contains(&weight) { return -1; }
        weights[column] = weight;
    }
    let allowed = (1u64 << columns) - 1;
    let mut row_masks = [0u64; MAX_ROWS];
    let mut block_left = [[0usize; MAX_COLUMNS]; MAX_ROWS];
    let mut block_right = [[0usize; MAX_COLUMNS]; MAX_ROWS];
    let mut block_count = [0usize; MAX_ROWS];
    for row in 0..rows {
        let raw = *input.add(2 + columns + row);
        if raw < 0 || raw as u64 & !allowed != 0 { return -1; }
        row_masks[row] = raw as u64;
        let mut column = 0;
        while column < columns {
            if row_masks[row] & (1u64 << column) == 0 { column += 1; continue; }
            let block = block_count[row];
            block_left[row][block] = column;
            while column + 1 < columns && row_masks[row] & (1u64 << (column + 1)) != 0 { column += 1; }
            block_right[row][block] = column;
            block_count[row] += 1;
            column += 1;
        }
    }

    if row_masks[..rows].iter().any(|&mask| mask == 0) {
        if output.is_null() || capacity < 8 { return -2; }
        for byte in 0..8 { *output.add(byte) = 255; }
        return 8;
    }

    let mut best_cost = 1_000_000i64;
    let mut stack = [[-1i8; MAX_ROWS]; MAX_STACK];
    let mut stack_size = 1usize;
    while stack_size > 0 {
        stack_size -= 1;
        let fixed = stack[stack_size];
        let mut left = [0usize; MAX_ROWS];
        let mut right = [0usize; MAX_ROWS];
        let mut count = 0usize;
        for row in 0..rows {
            if block_count[row] == 1 || fixed[row] >= 0 {
                let block = if block_count[row] == 1 { 0 } else { fixed[row] as usize };
                left[count] = block_left[row][block];
                right[count] = block_right[row][block];
                count += 1;
            }
        }
        let Some((lower_cost, lower_mask)) = interval_cover(&left, &right, count, &weights, columns) else { continue; };
        let mut extra_left = [0usize; MAX_ROWS];
        let mut extra_right = [0usize; MAX_ROWS];
        let mut extra_count = 0usize;
        for row in 0..rows {
            if row_masks[row] & lower_mask as u64 != 0 { continue; }
            let mut chosen = 0usize;
            let mut chosen_cost = 1_000_000i64;
            for block in 0..block_count[row] {
                let mut cheapest = 1_000_000i64;
                for column in block_left[row][block]..=block_right[row][block] {
                    cheapest = cheapest.min(weights[column]);
                }
                if cheapest < chosen_cost { chosen_cost = cheapest; chosen = block; }
            }
            extra_left[extra_count] = block_left[row][chosen];
            extra_right[extra_count] = block_right[row][chosen];
            extra_count += 1;
        }
        let Some((_extra_cost, extra_mask)) = interval_cover(&extra_left, &extra_right, extra_count, &weights, columns) else { continue; };
        let candidate_mask = lower_mask | extra_mask;
        let mut candidate_cost = 0i64;
        for column in 0..columns {
            if candidate_mask & (1i64 << column) != 0 { candidate_cost += weights[column]; }
        }
        best_cost = best_cost.min(candidate_cost);
        if best_cost <= lower_cost { continue; }
        let branch = (0..rows).find(|&row| block_count[row] > 1 && fixed[row] < 0);
        let Some(branch_row) = branch else { continue; };
        for block in (0..block_count[branch_row]).rev() {
            let mut child = fixed;
            child[branch_row] = block as i8;
            stack[stack_size] = child;
            stack_size += 1;
        }
    }
    let result = if best_cost == 1_000_000 { -1 } else { best_cost };
    if output.is_null() || capacity < 8 { return -2; }
    let bits = result as u64;
    for byte in 0..8 { *output.add(byte) = (bits >> (8 * byte)) as u8; }
    8
}
