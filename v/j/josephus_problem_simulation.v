module josephus_problem_simulation
@[export: 'josephus_problem_simulation']
pub fn josephus_problem_simulation(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    n := unsafe { values[0] }
    step := unsafe { values[1] }
    if n < 1 || n > 512 || step < 1 { return -1 }
    mut people := [512]i64{}
    mut remaining := usize(n)
    for i in 0 .. remaining { people[i] = i64(i) + 1 }
    mut current := usize(0)
    for remaining > 1 {
        offset := usize((step - 1) % i64(remaining))
        removed := (current + offset) % remaining
        for i := removed; i + 1 < remaining; i++ { people[i] = people[i + 1] }
        remaining--
        current = removed % remaining
    }
    return people[0]
}
