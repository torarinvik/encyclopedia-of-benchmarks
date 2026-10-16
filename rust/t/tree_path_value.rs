/// Port of Go Problem18's chunked search over its triangle-shaped DAG.
#[no_mangle]
pub extern "C" fn tree_path_value(packed: *const i64, length: usize) -> i64 {
    if packed.is_null() || length == 0 || length > 121 { return -1; }
    let packed = unsafe { std::slice::from_raw_parts(packed, length) };
    if !(1..=14).contains(&packed[0]) { return -1; }
    let depth = packed[0] as usize;
    let count = length - 1;
    if count == 0 { return 0; }

    let mut values = [0_i64; 120];
    let mut left_children = [-1_isize; 120];
    let mut right_children = [-1_isize; 120];
    for index in 0..count {
        values[index] = packed[index + 1];
        if (index == 0 && !(-1000..=1000).contains(&values[index]))
            || (index > 0 && !(1..=1000).contains(&values[index])) { return -1; }
    }

    let mut row_start = 0;
    let mut width = 1;
    while row_start < count {
        for column in 0..width {
            if row_start + column >= count { break; }
            let parent = row_start + column;
            let left_index = row_start + width + column;
            let right_index = left_index + 1;
            if left_index < count { left_children[parent] = left_index as isize; }
            if right_index < count { right_children[parent] = right_index as isize; }
        }
        row_start += width;
        width += 1;
    }

    let mut pivot = 0;
    let mut maximum = values[0];
    while left_children[pivot] >= 0 {
        let mut stack_node = [0_usize; 16];
        let mut stack_steps = [0_usize; 16];
        let mut stack_sum = [0_i64; 16];
        let mut stack_size = 1;
        stack_node[0] = pivot;
        stack_steps[0] = depth;
        stack_sum[0] = maximum;
        while stack_size > 0 {
            stack_size -= 1;
            let node = stack_node[stack_size];
            let steps = stack_steps[stack_size];
            let sum = stack_sum[stack_size];
            if steps == 0 {
                if sum > maximum { maximum = sum; pivot = node; }
                continue;
            }
            if right_children[node] >= 0 {
                let child = right_children[node] as usize;
                stack_node[stack_size] = child;
                stack_steps[stack_size] = steps - 1;
                stack_sum[stack_size] = sum + values[child];
                stack_size += 1;
            }
            if left_children[node] >= 0 {
                let child = left_children[node] as usize;
                stack_node[stack_size] = child;
                stack_steps[stack_size] = steps - 1;
                stack_sum[stack_size] = sum + values[child];
                stack_size += 1;
            } else if sum > maximum {
                maximum = sum;
                pivot = node;
            }
        }
    }
    maximum
}
