package josephus_problem_simulation
import "core:c"
@(export)
josephus_problem_simulation :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if length != 2 do return -1
    n := values[0]
    step := values[1]
    if n < 1 || n > 512 || step < 1 do return -1
    people: [512]i64
    remaining := c.size_t(n)
    for i := c.size_t(0); i < remaining; i += 1 { people[i] = i64(i) + 1 }
    current := c.size_t(0)
    for remaining > 1 {
        offset := c.size_t((step - 1) % i64(remaining))
        removed := (current + offset) % remaining
        for i := removed; i + 1 < remaining; i += 1 { people[i] = people[i + 1] }
        remaining -= 1
        current = removed % remaining
    }
    return people[0]
}
