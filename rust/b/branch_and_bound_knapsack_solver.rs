/// Breadth-first branch-and-bound for bounded 0/1 knapsack.
const MAX_ITEMS: usize = 8;
const MAX_NODES: usize = 511;

#[derive(Clone, Copy, Default)]
struct SearchNode {
    level: i32,
    weight: i32,
    value: i32,
    mask: i32,
}

fn upper_bound(weights: &[i32; MAX_ITEMS], item_values: &[i32; MAX_ITEMS],
               count: i32, capacity: i32, level: i32, weight: i32, value: i32) -> f64 {
    let mut available = capacity - weight;
    let mut bound = value as f64;
    let mut next = level + 1;
    while available > 0 && next < count {
        if weights[next as usize] <= available {
            bound += item_values[next as usize] as f64;
            available -= weights[next as usize];
        } else {
            bound += (item_values[next as usize] as f64 / weights[next as usize] as f64)
                * available as f64;
            available = 0;
        }
        next += 1;
    }
    bound
}

#[no_mangle]
pub extern "C" fn branch_and_bound_knapsack_solver(
    input: *const i64, length: usize, output: *mut u8, output_capacity: usize,
) -> i64 {
    if input.is_null() || length < 2 || length > 18 { return -1; }
    let input = unsafe { std::slice::from_raw_parts(input, length) };
    if !(0..=MAX_ITEMS as i64).contains(&input[0]) || !(0..=8000).contains(&input[1]) { return -1; }
    let count = input[0] as i32;
    let capacity = input[1] as i32;
    if length != 2 + 2 * count as usize { return -1; }

    let mut weights = [0_i32; MAX_ITEMS];
    let mut item_values = [0_i32; MAX_ITEMS];
    let mut item_ids = [0_i32; MAX_ITEMS];
    for index in 0..count as usize {
        let weight = input[2 + 2 * index];
        let value = input[3 + 2 * index];
        if !(1..=1000).contains(&weight) || !(1..=1000).contains(&value) { return -1; }
        let mut position = index;
        while position > 0
            && value * weights[position - 1] as i64
                > item_values[position - 1] as i64 * weight {
            weights[position] = weights[position - 1];
            item_values[position] = item_values[position - 1];
            item_ids[position] = item_ids[position - 1];
            position -= 1;
        }
        weights[position] = weight as i32;
        item_values[position] = value as i32;
        item_ids[position] = index as i32;
    }

    let mut queue = [SearchNode::default(); MAX_NODES];
    let mut head = 0;
    let mut tail = 1;
    queue[0] = SearchNode { level: -1, weight: 0, value: 0, mask: 0 };
    let mut best_value = 0;
    let mut best_mask = 0;
    while head < tail {
        let parent = queue[head];
        head += 1;
        if parent.level == count - 1 { continue; }
        let next = (parent.level + 1) as usize;
        let left = SearchNode {
            level: next as i32, weight: parent.weight + weights[next],
            value: parent.value + item_values[next], mask: parent.mask | (1 << next),
        };
        let right = SearchNode {
            level: next as i32, weight: parent.weight,
            value: parent.value, mask: parent.mask,
        };
        if left.weight <= capacity && left.value > best_value {
            best_value = left.value;
            best_mask = left.mask;
        }
        if upper_bound(&weights, &item_values, count, capacity, left.level, left.weight, left.value)
            > best_value as f64 && left.weight < capacity {
            queue[tail] = left; tail += 1;
        }
        if upper_bound(&weights, &item_values, count, capacity, right.level, right.weight, right.value)
            > best_value as f64 {
            queue[tail] = right; tail += 1;
        }
    }

    let mut selected = [0_u8; MAX_ITEMS];
    let mut selected_count = 0;
    for level in (0..count as usize).rev() {
        if best_mask & (1 << level) != 0 {
            selected[selected_count] = item_ids[level] as u8;
            selected_count += 1;
        }
    }
    if selected_count > output_capacity || (selected_count != 0 && output.is_null()) { return -2; }
    if selected_count != 0 {
        unsafe { std::ptr::copy_nonoverlapping(selected.as_ptr(), output, selected_count); }
    }
    selected_count as i64
}
