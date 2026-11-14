@[export: 'functional_graph_cycle_brent']
pub fn functional_graph_cycle_brent(input &i64, length usize) i64 {
    if length < 3 || length > 67 { return -1 }
    unsafe {
        if input == nil { return -1 }
        n, start := input[0], input[1]
        if n < 1 || n > 64 || start < 0 || start >= n || length != usize(n + 2) { return -1 }
        for i in 0 .. int(n) {
            if input[2+i] < 0 || input[2+i] >= n { return -1 }
        }
        mut checkpoint := start
        mut moving := input[2+int(start)]
        mut power := i64(1)
        mut period := i64(1)
        for checkpoint != moving {
            if power == period { checkpoint = moving; power *= 2; period = 0 }
            moving = input[2+int(moving)]
            period++
        }
        mut left := start
        mut right := start
        for _ in 0 .. int(period) { right = input[2+int(right)] }
        mut tail := i64(0)
        for left != right {
            left = input[2+int(left)]
            right = input[2+int(right)]
            tail++
        }
        return 65 * tail + period
    }
}
