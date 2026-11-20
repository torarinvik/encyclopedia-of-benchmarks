const MAX_N: usize = 8;
const MAX_INPUT: usize = 19;
const MAX_Q: usize = 32;

fn offer_state(
    q: usize,
    weight: i64,
    mask: i64,
    profit: i64,
    weights: &mut [i64; MAX_Q + 1],
    masks: &mut [i64; MAX_Q + 1],
    profits: &mut [i64; MAX_Q + 1],
) {
    if weight < weights[q]
        || (weight == weights[q]
            && (profit > profits[q] || (profit == profits[q] && mask < masks[q])))
    {
        weights[q] = weight;
        masks[q] = mask;
        profits[q] = profit;
    }
}

#[no_mangle]
pub unsafe extern "C" fn lawler_knapsack_profit_scaling_fptas(
    input: *const i64,
    length: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > MAX_INPUT {
        return -1;
    }
    let capacity = *input;
    let n64 = *input.add(1);
    if !(1..=30).contains(&capacity)
        || !(4..=MAX_N as i64).contains(&n64)
        || length != 2 + 2 * n64 as usize
    {
        return -1;
    }
    let n = n64 as usize;
    let mut weights = [0i64; MAX_N];
    let mut profits = [0i64; MAX_N];
    for i in 0..n {
        weights[i] = *input.add(2 + 2 * i);
        profits[i] = *input.add(3 + 2 * i);
        if !(1..=capacity).contains(&weights[i]) || !(32..=200).contains(&profits[i]) {
            return -1;
        }
    }

    let mut order = [0usize; MAX_N];
    for i in 0..n {
        order[i] = i;
    }
    for i in 1..n {
        let key = order[i];
        let mut j = i;
        while j > 0 {
            let previous = order[j - 1];
            let left = profits[key] * weights[previous];
            let right = profits[previous] * weights[key];
            if left < right || (left == right && key > previous) {
                break;
            }
            order[j] = previous;
            j -= 1;
        }
        order[j] = key;
    }

    let mut prefix_weight = 0i64;
    let mut prefix_profit = 0i64;
    let mut prefix_mask = 0i64;
    let mut p0 = 0i64;
    let mut exact = true;
    for position in 0..n {
        let item = order[position];
        if prefix_weight + weights[item] > capacity {
            exact = false;
            p0 = prefix_profit;
            for i in 0..n {
                p0 = p0.max(profits[i]);
            }
            break;
        }
        prefix_weight += weights[item];
        prefix_profit += profits[item];
        prefix_mask |= 1i64 << item;
        if prefix_weight == capacity {
            break;
        }
    }
    if exact {
        return (prefix_profit << 8) | prefix_mask;
    }

    let mut small = [0usize; MAX_N];
    let mut small_count = 0usize;
    let mut groups = [[0usize; MAX_N]; MAX_Q + 1];
    let mut group_count = [0usize; MAX_Q + 1];
    for item in 0..n {
        if 4 * profits[item] <= p0 {
            small[small_count] = item;
            small_count += 1;
        } else {
            let mut scaled = 0usize;
            for exponent in 0..=1 {
                let scale = 1i64 << exponent;
                if scale * p0 < 4 * profits[item] && 4 * profits[item] <= 2 * scale * p0 {
                    scaled = (scale * (16 * profits[item] / (scale * p0))) as usize;
                    break;
                }
            }
            if scaled == 0 || scaled > MAX_Q {
                return -1;
            }
            groups[scaled][group_count[scaled]] = item;
            group_count[scaled] += 1;
        }
    }

    let mut ordered_small = [0usize; MAX_N];
    let mut ordered_small_count = 0usize;
    for &item in order[..n].iter() {
        if small[..small_count].contains(&item) {
            ordered_small[ordered_small_count] = item;
            ordered_small_count += 1;
        }
    }

    let mut state_weight = [capacity + 1; MAX_Q + 1];
    let mut state_mask = [0i64; MAX_Q + 1];
    let mut state_profit = [0i64; MAX_Q + 1];
    state_weight[0] = 0;

    for q in (1..=MAX_Q).rev() {
        if group_count[q] == 0 {
            continue;
        }
        groups[q][..group_count[q]].sort_by(|&left, &right| {
            weights[left].cmp(&weights[right]).then(left.cmp(&right))
        });
        let kept = group_count[q].min(MAX_Q / q);
        let mut next_weight = [capacity + 1; MAX_Q + 1];
        let mut next_mask = [0i64; MAX_Q + 1];
        let mut next_profit = [0i64; MAX_Q + 1];
        for old_q in 0..=MAX_Q {
            if state_weight[old_q] > capacity {
                continue;
            }
            offer_state(
                old_q,
                state_weight[old_q],
                state_mask[old_q],
                state_profit[old_q],
                &mut next_weight,
                &mut next_mask,
                &mut next_profit,
            );
            let mut added_weight = 0i64;
            let mut added_profit = 0i64;
            let mut added_mask = 0i64;
            for take in 0..kept {
                let item = groups[q][take];
                added_weight += weights[item];
                if state_weight[old_q] + added_weight > capacity {
                    break;
                }
                added_profit += profits[item];
                added_mask |= 1i64 << item;
                let destination = old_q + q * (take + 1);
                if destination <= MAX_Q {
                    offer_state(
                        destination,
                        state_weight[old_q] + added_weight,
                        state_mask[old_q] | added_mask,
                        state_profit[old_q] + added_profit,
                        &mut next_weight,
                        &mut next_mask,
                        &mut next_profit,
                    );
                }
            }
        }
        let mut best_higher_weight = capacity + 1;
        for scaled in (0..=MAX_Q).rev() {
            if next_weight[scaled] <= capacity && next_weight[scaled] < best_higher_weight {
                best_higher_weight = next_weight[scaled];
            } else {
                next_weight[scaled] = capacity + 1;
                next_mask[scaled] = 0;
                next_profit[scaled] = 0;
            }
        }
        state_weight = next_weight;
        state_mask = next_mask;
        state_profit = next_profit;
    }

    let mut best_score = -1i64;
    let mut best_profit = -1i64;
    let mut best_weight = capacity + 1;
    let mut best_mask = 0i64;
    for q in 0..=MAX_Q {
        if state_weight[q] > capacity {
            continue;
        }
        let mut used = state_weight[q];
        let mut actual_profit = state_profit[q];
        let mut mask = state_mask[q];
        for &item in ordered_small[..ordered_small_count].iter() {
            if used + weights[item] > capacity {
                break;
            }
            used += weights[item];
            actual_profit += profits[item];
            mask |= 1i64 << item;
        }
        let small_profit = actual_profit - state_profit[q];
        let score = p0 * q as i64 + 16 * small_profit;
        if score > best_score
            || (score == best_score
                && (actual_profit > best_profit
                    || (actual_profit == best_profit
                        && (used < best_weight || (used == best_weight && mask < best_mask))))))
        {
            best_score = score;
            best_profit = actual_profit;
            best_weight = used;
            best_mask = mask;
        }
    }
    (best_profit << 8) | best_mask
}
