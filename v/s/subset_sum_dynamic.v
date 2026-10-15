module subset_sum_dynamic

const max_items = 16
const width = 801
const states = (max_items + 1) * width

fn subset_sum_dynamic_search(input &i64, item_count int, index int, remaining i64, mut memo []i64) i64 {
    if remaining == 0 { return 1 }
    if index == item_count { return 0 }
    state := index * width + int(remaining + 400)
    if memo[state] != -2 { return memo[state] }
    mut result := subset_sum_dynamic_search(input, item_count, index + 1,
        remaining - unsafe { input[index + 1] }, mut memo)
    if result == 0 {
        result = subset_sum_dynamic_search(input, item_count, index + 1, remaining, mut memo)
    }
    memo[state] = result
    return result
}

@[export: 'subset_sum_dynamic']
pub fn subset_sum_dynamic(input &i64, length usize) i64 {
    if length == 0 || length > max_items + 1 { return -1 }
    unsafe {
        target := input[0]
        if target < -80 || target > 80 { return -1 }
        for index in 1 .. int(length) {
            if input[index] < -20 || input[index] > 20 { return -1 }
        }
        mut memo := []i64{len: states, init: -2}
        return subset_sum_dynamic_search(input, int(length) - 1, 0, target, mut memo)
    }
}
