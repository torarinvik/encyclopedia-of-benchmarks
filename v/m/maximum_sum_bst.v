module maximum_sum_bst

@[export: 'maximum_sum_bst']
pub fn maximum_sum_bst(input &i64, length usize) i64 {
    if length < 1 || length > 32 || unsafe { input == nil } { return -1 }
    unsafe {
        if input[0] < 0 || input[0] > 31 || length != usize(input[0]) + 1 { return -1 }
        count := int(input[0])
        for i in 0 .. count {
            if input[i + 1] < -1 || input[i + 1] > 1_000_000 { return -1 }
            if input[i + 1] != -1 && i > 0 && input[(i - 1) / 2 + 1] == -1 { return -1 }
        }
        if count == 0 { return 0 }
        mut valid := []bool{len: 31, init: false}
        mut subtree_min := []i64{len: 31, init: 0}
        mut subtree_max := []i64{len: 31, init: 0}
        mut subtree_sum := []i64{len: 31, init: 0}
        mut best := []i64{len: 31, init: 0}
        mut remaining := count
        for remaining > 0 {
            remaining--
            i := remaining
            if input[i + 1] == -1 { valid[i] = true; subtree_min[i] = 1_000_001; subtree_max[i] = -1; continue }
            left := 2 * i + 1; right := left + 1
            left_valid := left >= count || valid[left]
            right_valid := right >= count || valid[right]
            mut left_max := i64(-1); mut right_min := i64(1_000_001); mut left_min := i64(1_000_001); mut right_max := i64(-1)
            mut left_sum := i64(0); mut right_sum := i64(0); mut left_best := i64(0); mut right_best := i64(0)
            if left < count { left_max = subtree_max[left]; left_min = subtree_min[left]; left_sum = subtree_sum[left]; left_best = best[left] }
            if right < count { right_min = subtree_min[right]; right_max = subtree_max[right]; right_sum = subtree_sum[right]; right_best = best[right] }
            value := input[i + 1]
            if left_valid && right_valid && left_max < value && value < right_min {
                valid[i] = true; subtree_min[i] = min(left_min, value); subtree_max[i] = max(right_max, value)
                subtree_sum[i] = left_sum + right_sum + value; best[i] = max(subtree_sum[i], left_best, right_best)
            } else { best[i] = max(left_best, right_best) }
        }
        return best[0]
    }
}
