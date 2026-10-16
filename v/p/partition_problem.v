module partition_problem

const max_items = 16
const max_total = 1024

@[export: 'partition_problem']
pub fn partition_problem(input &i64, length usize) i64 {
    if length == 0 || length > max_items { return -1 }
    unsafe {
        mut total := i64(0)
        for index in 0 .. int(length) {
            value := input[index]
            if value < 0 || value > 256 || total > max_total - value { return -1 }
            total += value
        }
        if (total & 1) != 0 { return 0 }
        target := int(total / 2)
        mut reachable := []bool{len: max_total + 1, init: false}
        reachable[0] = true
        for index in 0 .. int(length) {
            value := int(input[index])
            if value <= target {
                mut sum := target
                for sum >= value {
                    if reachable[sum - value] { reachable[sum] = true }
                    if sum == value { break }
                    sum--
                }
            }
        }
        return i64(reachable[target])
    }
}
