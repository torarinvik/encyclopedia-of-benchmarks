module largest_product_in_a_grid

@[export: 'largest_product_in_a_grid']
pub fn largest_product_in_a_grid(values &i64, length usize) i64 {
    unsafe {
        if values == nil || length < 2 || length > 3971 { return -1 }
        rows := values[0]
        cols := values[1]
        if rows < 0 || rows > 63 || cols < 0 || cols > 63 { return -1 }

        expected_length := usize(2) + usize(rows) * usize(cols)
        if length != expected_length { return -1 }
        for index in 2 .. int(length) {
            if values[index] < 0 || values[index] > 1000 { return -1 }
        }

        mut best := i64(0)
        for row in 0 .. int(rows) {
            for col in 0 .. int(cols) {
                for direction in 0 .. 4 {
                    mut row_step := i64(0)
                    mut col_step := i64(1)
                    if direction == 1 {
                        row_step = 1
                        col_step = 0
                    } else if direction == 2 {
                        row_step = 1
                        col_step = 1
                    } else if direction == 3 {
                        row_step = 1
                        col_step = -1
                    }

                    mut product := i64(1)
                    for offset in 0 .. 4 {
                        next_row := i64(row) + i64(offset) * row_step
                        next_col := i64(col) + i64(offset) * col_step
                        if next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols {
                            product = 0
                            break
                        }
                        index := usize(2) + usize(next_row) * usize(cols) + usize(next_col)
                        product *= values[index]
                    }
                    best = max(best, product)
                }
            }
        }
        return best
    }
}
