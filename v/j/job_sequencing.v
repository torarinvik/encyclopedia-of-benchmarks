module job_sequencing

const max_jobs = 32
const max_input_length = 98
const max_profit = i64(1_000_000)

@[export: 'job_sequencing']
pub fn job_sequencing(input &i64, length usize, mut output &u8, capacity usize) i64 {
    if unsafe { input == nil } || length < 4 || length > max_input_length { return -1 }
    unsafe {
        if input[0] < 1 || input[0] > max_jobs { return -1 }
        n := int(input[0])
        if length != usize(1 + 3 * n) { return -1 }
        mut seen := [128]u8{}
        mut previous_profit := max_profit + 1
        for i in 0 .. n {
            base := 1 + 3 * i
            id := input[base]
            deadline := input[base + 1]
            profit := input[base + 2]
            letter := (id >= 65 && id <= 90) || (id >= 97 && id <= 122)
            if !letter || seen[int(id)] != 0 || deadline < 1 || deadline > i64(n) || profit < 1 || profit > max_profit || profit >= previous_profit { return -1 }
            seen[int(id)] = 1
            previous_profit = profit
        }
        mut slots := [32]u8{}
        mut total_profit := i64(0)
        for i in 0 .. n {
            base := 1 + 3 * i
            deadline := int(input[base + 1])
            for remaining := deadline; remaining > 0; remaining-- {
                slot := remaining - 1
                if slots[slot] == 0 { slots[slot] = u8(input[base]); total_profit += input[base + 2]; break }
            }
        }
        mut count := 0
        for slot in 0 .. n { if slots[slot] != 0 { count++ } }
        required := 9 + count
        if unsafe { output == nil } || capacity < usize(required) { return -2 }
        output[0] = u8(count)
        for byte in 0 .. 8 { output[1 + byte] = u8((u64(total_profit) >> (8 * byte)) & 255) }
        mut written := 9
        for slot in 0 .. n { if slots[slot] != 0 { output[written] = slots[slot]; written++ } }
        return i64(required)
    }
}
