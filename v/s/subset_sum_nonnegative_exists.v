module subset_sum_nonnegative_exists

const max_items = 64
const max_target = i64(4096)
const width = 4097

@[export: 'subset_sum_nonnegative_exists']
pub fn subset_sum_nonnegative_exists(input &i64, length usize) i64 {
    if length == 0 || length > max_items + 1 { return -1 }
    unsafe {
        target := input[0]
        if target < 0 || target > max_target { return -1 }
        for index in 1 .. int(length) {
            item := input[index]
            if item < 0 || item > max_target { return -1 }
        }

        mut reachable := [width]bool{}
        reachable[0] = true
        for index in 1 .. int(length) {
            item := input[index]
            mut sum := target
            for sum >= item {
                if reachable[int(sum - item)] { reachable[int(sum)] = true }
                sum -= 1
            }
        }
        if reachable[int(target)] { return 1 }
        return 0
    }
}
