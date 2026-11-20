from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn find_root(inout parent: InlineArray[Int32, 65], vertex_value: Int) -> Int:
    var vertex = vertex_value
    while Int(parent[vertex]) != vertex:
        let next = Int(parent[vertex])
        parent[vertex] = parent[next]
        vertex = Int(parent[vertex])
    return vertex

fn unite(inout parent: InlineArray[Int32, 65],
         inout component_size: InlineArray[Int32, 65], left: Int, right: Int):
    var a = find_root(inout parent, left)
    var b = find_root(inout parent, right)
    if a == b:
        return
    if component_size[a] < component_size[b]:
        let temporary = a
        a = b
        b = temporary
    parent[b] = Int32(a)
    component_size[a] += component_size[b]

fn build_dsu(inout grid: InlineArray[UInt8, 64], rows: Int, columns: Int,
             inout parent: InlineArray[Int32, 65],
             inout component_size: InlineArray[Int32, 65]):
    let cells = rows * columns
    for cell in range(cells):
        parent[cell] = Int32(cell)
        component_size[cell] = Int32(grid[cell])
    parent[cells] = Int32(cells)
    component_size[cells] = 0
    for cell in range(cells):
        if grid[cell] == 0:
            continue
        let row = cell // columns
        let column = cell % columns
        if row == 0:
            unite(inout parent, inout component_size, cell, cells)
        if row > 0 and grid[cell - columns] != 0:
            unite(inout parent, inout component_size, cell, cell - columns)
        if column > 0 and grid[cell - 1] != 0:
            unite(inout parent, inout component_size, cell, cell - 1)

fn put_i64_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int32):
    let bits = UInt64(value)
    for byte in range(8):
        output[offset + byte] = UInt8((bits >> UInt(8 * byte)) & 255)

@export("bricks_falling_when_hit_reverse_dsu")
fn bricks_falling_when_hit_reverse_dsu(
    input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t,
) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 100:
        return -1
    let row_value = input[0]
    let column_value = input[1]
    let hit_value = input[2]
    if row_value < 1 or row_value > 8 or column_value < 1 or column_value > 8 or hit_value < 0 or hit_value > 16:
        return -1
    let rows = Int(row_value)
    let columns = Int(column_value)
    let cells = rows * columns
    let hits = Int(hit_value)
    if hits > cells or length != c_size_t(3 + cells + 2 * hits):
        return -1

    var grid = InlineArray[UInt8, 64]()
    var parent = InlineArray[Int32, 65]()
    var component_size = InlineArray[Int32, 65]()
    for cell in range(cells):
        let value = input[3 + cell]
        if value != 0 and value != 1:
            return -1
        grid[cell] = UInt8(value)
    let hit_start = 3 + cells
    for index in range(hits):
        let row = input[hit_start + 2 * index]
        let column = input[hit_start + 2 * index + 1]
        if row < 0 or row >= row_value or column < 0 or column >= column_value:
            return -1
        for previous in range(index):
            if input[hit_start + 2 * previous] == row and input[hit_start + 2 * previous + 1] == column:
                return -1

    build_dsu(inout grid, rows, columns, inout parent, inout component_size)
    let roof_root = find_root(inout parent, cells)
    for cell in range(cells):
        if grid[cell] != 0 and find_root(inout parent, cell) != roof_root:
            return -1

    let required = hits * 8
    if capacity < c_size_t(required) or (required > 0 and output == UnsafePointer[UInt8, MutAnyOrigin]()):
        return -2
    if hits == 0:
        return 0
    for index in range(hits):
        let row = Int(input[hit_start + 2 * index])
        let column = Int(input[hit_start + 2 * index + 1])
        grid[row * columns + column] = 0
    build_dsu(inout grid, rows, columns, inout parent, inout component_size)

    for reverse in range(hits):
        let index = hits - 1 - reverse
        let row = Int(input[hit_start + 2 * index])
        let column = Int(input[hit_start + 2 * index + 1])
        let cell = row * columns + column
        if input[3 + cell] == 0:
            put_i64_le(output, index * 8, 0)
            continue
        let before = component_size[find_root(inout parent, cells)]
        grid[cell] = 1
        parent[cell] = Int32(cell)
        component_size[cell] = 1
        if row == 0:
            unite(inout parent, inout component_size, cell, cells)
        if row > 0 and grid[cell - columns] != 0:
            unite(inout parent, inout component_size, cell, cell - columns)
        if row + 1 < rows and grid[cell + columns] != 0:
            unite(inout parent, inout component_size, cell, cell + columns)
        if column > 0 and grid[cell - 1] != 0:
            unite(inout parent, inout component_size, cell, cell - 1)
        if column + 1 < columns and grid[cell + 1] != 0:
            unite(inout parent, inout component_size, cell, cell + 1)
        let after = component_size[find_root(inout parent, cells)]
        let fallen: Int32 = if after > before + 1 then after - before - 1 else 0
        put_i64_le(output, index * 8, fallen)
    return Int64(required)
