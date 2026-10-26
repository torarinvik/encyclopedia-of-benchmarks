package optimal_stable_marriage

import "core:c"

MAX_N :: 8
MAX_INPUT_LENGTH :: 129

@(export, link_name="optimal_stable_marriage")
optimal_stable_marriage :: proc "c" (input: [^]i64, length: c.size_t,
    output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 1 || length > c.size_t(MAX_INPUT_LENGTH) do return -1
    n_arg := input[0]
    if n_arg < 0 || n_arg > MAX_N do return -1
    n := int(n_arg)
    side_size := n * n
    if length != c.size_t(1 + 2 * side_size) do return -1

    men_preferences: [64]int
    women_rank: [64]int
    for row := 0; row < 2 * n; row += 1 {
        seen: [MAX_N]bool
        for id := 0; id < MAX_N; id += 1 { seen[id] = false }
        start := 1 + row * n
        if row >= n { start = 1 + side_size + (row - n) * n }
        for rank := 0; rank < n; rank += 1 {
            value := input[start + rank]
            if value < 0 || value >= n_arg || seen[int(value)] do return -1
            participant := int(value)
            seen[participant] = true
            if row < n { men_preferences[row * n + rank] = participant }
            else { women_rank[(row - n) * n + participant] = rank }
        }
    }
    output_bytes := c.size_t(16 * n)
    if output == nil || capacity < output_bytes do return -2

    final_partner: [MAX_N]i64
    for man := 0; man < n; man += 1 { final_partner[man] = -1 }
    for threshold := 0; threshold < n; threshold += 1 {
        woman_partner: [MAX_N]i64
        man_partner: [MAX_N]i64
        next_rank: [MAX_N]int
        queue: [MAX_N]int
        for i := 0; i < n; i += 1 {
            woman_partner[i] = -1
            man_partner[i] = -1
            next_rank[i] = 0
            queue[i] = i
        }
        head, tail, queued := 0, 0, n
        for queued > 0 {
            man := queue[head]
            head = (head + 1) % n
            queued -= 1
            for next_rank[man] < n {
                rank := next_rank[man]
                next_rank[man] += 1
                woman := men_preferences[man * n + rank]
                if rank > threshold || women_rank[woman * n + man] > threshold { continue }
                incumbent := woman_partner[woman]
                if incumbent < 0 || women_rank[woman * n + man] < women_rank[woman * n + int(incumbent)] {
                    woman_partner[woman] = i64(man)
                    man_partner[man] = i64(woman)
                    if incumbent >= 0 {
                        man_partner[int(incumbent)] = -1
                        queue[tail] = int(incumbent)
                        tail = (tail + 1) % n
                        queued += 1
                    }
                    break
                }
                queue[tail] = man
                tail = (tail + 1) % n
                queued += 1
                break
            }
        }
        matched := 0
        for man := 0; man < n; man += 1 { if man_partner[man] >= 0 { matched += 1 } }
        if matched == n {
            for man := 0; man < n; man += 1 { final_partner[man] = man_partner[man] }
            break
        }
    }
    for man := 0; man < n; man += 1 {
        values := [2]i64{i64(man), final_partner[man]}
        for item := 0; item < 2; item += 1 {
            bits := transmute(u64)(values[item])
            for byte := 0; byte < 8; byte += 1 {
                output[(man * 2 + item) * 8 + byte] = u8(bits & 255)
                bits >>= 8
            }
        }
    }
    return i64(output_bytes)
}
