# Bounded Rodinia row-wise grid path dynamic program.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("rodinia_pathfinder")
fn rodinia_pathfinder(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 4 or length > 1027: return -1
    let cv = input[0]
    let rv = input[1]
    let hv = input[2]
    if cv < 1 or cv > 32 or rv < 1 or rv > 32 or hv < 1 or hv > 4 or length != c_size_t(3+cv*rv): return -1
    let cols = Int(cv)
    let rows = Int(rv)
    let height = Int(hv)
    var grid = List[Int64](capacity=cols*rows)
    var previous = List[Int64](capacity=cols)
    var current = List[Int64](capacity=cols)
    for i in range(cols*rows):
        let value = input[3+i]
        if value < 0 or value > 9: return -1
        grid.append(value)
    for i in range(cols):
        previous.append(grid[i]); current.append(0)
    var first = 1
    while first < rows:
        var steps = height
        if steps > rows-first: steps = rows-first
        for step in range(steps):
            let row = first+step
            for col in range(cols):
                var best = previous[col]
                if col > 0 and previous[col-1] < best: best = previous[col-1]
                if col+1 < cols and previous[col+1] < best: best = previous[col+1]
                current[col] = best+grid[row*cols+col]
            for col in range(cols): previous[col] = current[col]
        first += height
    var best = previous[0]
    for col in range(1,cols):
        if previous[col] < best: best = previous[col]
    return best
