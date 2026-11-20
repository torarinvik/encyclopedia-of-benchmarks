from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("grid_shortest_path_obstacle_elimination")
fn grid_shortest_path_obstacle_elimination(
    values: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t
) abi("C") -> Int64:
    if values == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 40:
        return -2
    let rows = values[0]
    let columns = values[1]
    let budget = values[2]
    if rows < 1 or rows > 6 or columns < 1 or columns > 6 or budget < 0 or budget > 6:
        return -2
    if length != c_size_t(3 + rows * columns):
        return -2

    let cell_count = Int(rows * columns)
    var cells = InlineArray[Int64, 36](fill=0)
    for cell in range(cell_count):
        let value = values[3 + cell]
        if value != 0 and value != 1:
            return -2
        cells[cell] = value
    if cells[0] != 0 or cells[cell_count - 1] != 0:
        return -2

    let stride = Int(budget + 1)
    var queue = InlineArray[Int64, 252](fill=0)
    var distance = InlineArray[Int64, 252](fill=-1)
    var head = 0
    var tail = 1
    let start = Int(budget)
    queue[0] = Int64(start)
    distance[start] = 0

    while head < tail:
        let state = Int(queue[head])
        head += 1
        let cell = state // stride
        let remaining = state % stride
        if cell + 1 == cell_count:
            return distance[state]
        let row = cell // Int(columns)
        let column = cell % Int(columns)
        var next_rows = InlineArray[Int, 4](fill=0)
        var next_columns = InlineArray[Int, 4](fill=0)
        next_rows[0] = row - 1
        next_rows[1] = row
        next_rows[2] = row
        next_rows[3] = row + 1
        next_columns[0] = column
        next_columns[1] = column - 1
        next_columns[2] = column + 1
        next_columns[3] = column
        for direction in range(4):
            let next_row = next_rows[direction]
            let next_column = next_columns[direction]
            if next_row < 0 or next_row >= Int(rows) or next_column < 0 or next_column >= Int(columns):
                continue
            let next_cell = next_row * Int(columns) + next_column
            let next_remaining = remaining - Int(cells[next_cell])
            if next_remaining < 0:
                continue
            let next_state = next_cell * stride + next_remaining
            if distance[next_state] != -1:
                continue
            distance[next_state] = distance[state] + 1
            queue[tail] = Int64(next_state)
            tail += 1
    return -1
