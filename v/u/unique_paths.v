module unique_paths

// Count right-and-down paths with one row of dynamic programming.
@[export: 'unique_paths']
pub fn unique_paths(rows u64, columns u64) i64 {
    if rows == 0 || columns == 0 || rows > 34 || columns > 34 { return -1 }
    width := if rows < columns { rows } else { columns }
    height := if rows < columns { columns } else { rows }
    mut paths := [34]i64{init: 0}
    for column in u64(0) .. width {
        paths[int(column)] = 1
    }
    mut row := u64(1)
    for row < height {
        for column in u64(1) .. width {
            paths[int(column)] += paths[int(column - 1)]
        }
        row++
    }
    return paths[int(width - 1)]
}
