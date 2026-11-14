# Copyright (c) 2012-2013 Argonne National Laboratory
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, UnsafePointer

fn xs_bracket(grid: List[Int64], base: Int, count: Int, query: Int64) -> Int:
    if grid[base] > query: return 0
    if grid[base+count-1] < query: return count-2
    var lo = 0
    var hi = count-1
    while lo <= hi:
        let mid = lo+(hi-lo)//2
        if grid[base+mid] < query: lo = mid+1
        elif grid[base+mid] > query: hi = mid-1
        else: return mid
    return hi

@export("doe_xsbench_unionized_macro_xs")
fn doe_xsbench_unionized_macro_xs(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t) abi("C") -> Float64:
    let invalid = Float64(-1.0e300)
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 22 or length > 232: return invalid
    let nv = input[0]; let gv = input[1]; let mv = input[2]; let query = input[3]
    if nv < 1 or nv > 4 or gv < 2 or gv > 5 or mv < 1 or mv > nv or query < 0 or query > 1000000: return invalid
    let n = Int(nv); let g = Int(gv); let m = Int(mv); let total = n*g
    let union_start = 4+2*m
    let pointer_start = union_start+total
    let grid_start = pointer_start+total*n
    if length != c_size_t(grid_start+6*total): return invalid
    var ids = List[Int](capacity=m)
    var concentrations = List[Float64](capacity=m)
    var used = 0
    for i in range(m):
        let id = input[4+2*i]; let concentration = input[5+2*i]
        if id < 0 or id >= nv or concentration < 0 or concentration > 1000000: return invalid
        if (used & (1 << Int(id))) != 0: return invalid
        used |= 1 << Int(id)
        ids.append(Int(id)); concentrations.append(Float64(concentration)/1000000.0)
    var union_grid = List[Int64](capacity=total)
    for i in range(total):
        let energy = input[union_start+i]
        if energy < 0 or energy > 1000000: return invalid
        if i > 0 and energy <= union_grid[i-1]: return invalid
        union_grid.append(energy)
    var grid = List[Int64](capacity=total)
    for nuclide in range(n):
        for point in range(g):
            let record = grid_start+6*(nuclide*g+point)
            let energy = input[record]
            if energy < 0 or energy > 1000000: return invalid
            if point > 0 and energy <= grid[nuclide*g+point-1]: return invalid
            grid.append(energy)
            for channel in range(1,6):
                if input[record+channel] < 0 or input[record+channel] > 1000000: return invalid
    for row in range(total):
        var matches = 0
        for energy in grid:
            if energy == union_grid[row]: matches += 1
        if matches != 1: return invalid
        for nuclide in range(n):
            if input[pointer_start+row*n+nuclide] != Int64(xs_bracket(grid,nuclide*g,g,union_grid[row])): return invalid
    var lo = 0
    var hi = total-1
    while hi-lo > 1:
        let mid = lo+(hi-lo)//2
        if union_grid[mid] > query: hi = mid
        else: lo = mid
    var macro_xs = List[Float64](capacity=5)
    for _ in range(5): macro_xs.append(0.0)
    let q = Float64(query)/1000000.0
    for item in range(m):
        let nuclide = ids[item]
        var index = Int(input[pointer_start+lo*n+nuclide])
        if index == g-1: index -= 1
        let low = grid_start+6*(nuclide*g+index)
        let high = low+6
        let low_energy = Float64(input[low])/1000000.0
        let high_energy = Float64(input[high])/1000000.0
        let factor = (high_energy-q)/(high_energy-low_energy)
        for channel in range(5):
            let low_xs = Float64(input[low+1+channel])/1000000.0
            let high_xs = Float64(input[high+1+channel])/1000000.0
            macro_xs[channel] += (high_xs-factor*(high_xs-low_xs))*concentrations[item]
    return macro_xs[0]+2.0*macro_xs[1]+3.0*macro_xs[2]+5.0*macro_xs[3]+7.0*macro_xs[4]
