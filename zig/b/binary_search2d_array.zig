fn searchRow(values: []const i64, rowBase: i64, low: i64, high: i64, target: i64) i64 {
    var lo = low;
    var hi = high;
    while (lo <= hi) {
        const middle = lo + @divTrunc(hi - lo, 2);
        const value = values[@intCast(3 + rowBase + middle)];
        if (value == target) return middle;
        if (value < target) lo = middle + 1 else hi = middle - 1;
    }
    return -1;
}

pub export fn binary_search2d_array(pointer: [*]const i64, length: usize) i64 {
    if (length < 3) return -1;
    const values = pointer[0..length];
    const rows = values[0];
    const cols = values[1];
    const target = values[2];
    if (rows < 2 or rows > 32 or cols < 3 or cols > 32) return -1;
    if (length != 3 + @as(usize, @intCast(rows * cols))) return -1;
    const middleCol = @divTrunc(cols, 2);
    var startRow: i64 = 0;
    var endRow = rows - 1;
    while (startRow < endRow - 1) {
        const middleRow = startRow + @divTrunc(endRow - startRow, 2);
        const value = values[@intCast(3 + middleRow * cols + middleCol)];
        if (value == target) return middleRow * cols + middleCol;
        if (value < target) startRow = middleRow else endRow = middleRow;
    }
    if (values[@intCast(3 + startRow * cols + middleCol)] == target) return startRow * cols + middleCol;
    if (values[@intCast(3 + endRow * cols + middleCol)] == target) return endRow * cols + middleCol;
    if (target <= values[@intCast(3 + startRow * cols + middleCol - 1)]) {
        const col = searchRow(values, startRow * cols, 0, middleCol - 1, target);
        return if (col < 0) -1 else startRow * cols + col;
    }
    if (target >= values[@intCast(3 + startRow * cols + middleCol + 1)] and
        target <= values[@intCast(3 + startRow * cols + cols - 1)]) {
        const col = searchRow(values, startRow * cols, middleCol + 1, cols - 1, target);
        return if (col < 0) -1 else startRow * cols + col;
    }
    if (target <= values[@intCast(3 + endRow * cols + middleCol - 1)]) {
        const col = searchRow(values, endRow * cols, 0, middleCol - 1, target);
        return if (col < 0) -1 else endRow * cols + col;
    }
    const col = searchRow(values, endRow * cols, middleCol + 1, cols - 1, target);
    return if (col < 0) -1 else endRow * cols + col;
}
