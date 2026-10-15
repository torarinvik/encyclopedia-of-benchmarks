module josephus_problem
@[export: 'josephus_problem']
pub fn josephus_problem(values &i64, length usize) i64 {
    if length != 2 { return -1 }
    n := unsafe { values[0] }
    step := unsafe { values[1] }
    if n < 1 || n > 100000 || step < 1 { return -1 }
    mut winner := i64(0)
    for size := i64(1); size <= n; size++ {
        winner = (winner + step % size) % size
    }
    return winner + 1
}
