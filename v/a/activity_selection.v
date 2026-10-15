module activity_selection

// Count a maximum set of non-overlapping half-open activities.
@[export: 'activity_selection']
pub fn activity_selection(input &i64, length usize) i64 {
    if length == 0 { return -1 }
    first := unsafe { input[0] }
    if first < 0 || first > 64 { return -1 }
    count := int(first)
    if length != usize(1 + 2 * count) { return -1 }
    if count == 0 { return 0 }
    mut starts := [64]i64{init: 0}
    mut finishes := [64]i64{init: 0}
    for index in 0 .. count {
        starts[index] = unsafe { input[1 + 2 * index] }
        finishes[index] = unsafe { input[2 + 2 * index] }
        if starts[index] > finishes[index] { return -1 }
    }
    for index in 1 .. count {
        start := starts[index]
        finish := finishes[index]
        mut position := index
        for position > 0 && (finishes[position - 1] > finish ||
            (finishes[position - 1] == finish && starts[position - 1] > start)) {
            starts[position] = starts[position - 1]
            finishes[position] = finishes[position - 1]
            position--
        }
        starts[position] = start
        finishes[position] = finish
    }
    mut selected := i64(1)
    mut last_finish := finishes[0]
    for index in 1 .. count {
        if starts[index] >= last_finish {
            selected++
            last_finish = finishes[index]
        }
    }
    return selected
}
