from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

@export("scimark2_sor")
fn scimark2_sor(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 67: return -1
    let rv = input[0]; let cv = input[1]; let iterations = input[2]
    if rv < 2 or rv > 8 or cv < 2 or cv > 8 or iterations < 0 or iterations > 8: return -1
    let rows = Int(rv); let cols = Int(cv); let cells = rows*cols
    if length != c_size_t(3+cells): return -1
    var grid = List[Int64](capacity=cells)
    for i in range(cells):
        let value = input[3+i]
        if value < -1000 or value > 1000: return -1
        grid.append(value)
    for _ in range(Int(iterations)):
        for row in range(1,rows-1):
            for column in range(1,cols-1):
                let i = row*cols+column
                let neighbors = grid[i-cols]+grid[i+cols]+grid[i-1]+grid[i+1]
                let numerator = 1250*neighbors-1000*grid[i]
                if numerator < 0: grid[i] = -((-numerator)//4000)
                else: grid[i] = numerator//4000
    var checksum = Int64(0)
    for i in range(cells): checksum += Int64(i+1)*grid[i]
    return checksum
