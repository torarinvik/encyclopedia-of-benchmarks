package largest_product_in_a_grid

import "core:c"

@(export)
largest_product_in_a_grid :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 2 || length > c.size_t(3971) do return -1
    rows := values[0]
    cols := values[1]
    if rows < 0 || rows > 63 || cols < 0 || cols > 63 do return -1

    expected_length := c.size_t(2) + c.size_t(rows) * c.size_t(cols)
    if length != expected_length do return -1
    for index := c.size_t(2); index < length; index += 1 {
        if values[index] < 0 || values[index] > 1000 do return -1
    }

    best := i64(0)
    for row := c.size_t(0); row < c.size_t(rows); row += 1 {
        for col := c.size_t(0); col < c.size_t(cols); col += 1 {
            for direction := c.size_t(0); direction < 4; direction += 1 {
                row_step := i64(0)
                col_step := i64(1)
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

                product := i64(1)
                for offset := i64(0); offset < 4; offset += 1 {
                    next_row := i64(row) + offset * row_step
                    next_col := i64(col) + offset * col_step
                    if next_row < 0 || next_row >= rows || next_col < 0 || next_col >= cols {
                        product = 0
                        break
                    }
                    index := c.size_t(2) + c.size_t(next_row) * c.size_t(cols) + c.size_t(next_col)
                    product *= values[index]
                }
                best = max(best, product)
            }
        }
    }
    return best
}
