# Forward integer 5/3 lifting with Rodinia's linear band layout.
from std.collections import List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn dwt_trunc(value: Int64, divisor: Int64) -> Int64:
    if value < 0: return -((-value)//divisor)
    return value//divisor

fn dwt_line(line: List[Int64], n: Int, mut transformed: List[Int64]):
    let half = n//2
    var detail = List[Int64](capacity=half)
    for j in range(half):
        let left = line[2*j]
        var right = left
        if j+1 < half: right = line[2*j+2]
        detail.append(line[2*j+1]-dwt_trunc(left+right,2))
    transformed[0] = line[0]+dwt_trunc(detail[0]+detail[0]+2,4)
    for j in range(1,half): transformed[j] = line[2*j]+dwt_trunc(detail[j-1]+detail[j]+2,4)
    for j in range(half): transformed[half+j] = detail[j]

@export("rodinia_dwt2d")
fn rodinia_dwt2d(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                 output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 3 or length > 259: return -1
    let wv = input[0]; let hv = input[1]; let lv = input[2]
    if wv < 2 or wv > 16 or hv < 2 or hv > 16 or lv < 1 or lv > 3: return -1
    let factor = Int64(1) << Int(lv)
    if wv < factor or hv < factor or wv%factor != 0 or hv%factor != 0 or length != c_size_t(3+wv*hv): return -1
    let width = Int(wv); let height = Int(hv); let levels = Int(lv)
    let cells = width*height
    var plane = List[Int64](capacity=cells)
    var vertical = List[Int64](capacity=cells)
    var next = List[Int64](capacity=cells)
    for i in range(cells):
        let value = input[3+i]
        if value < 0 or value > 255: return -1
        plane.append(value-128); vertical.append(0); next.append(0)
    var line = List[Int64](capacity=16)
    var transformed = List[Int64](capacity=16)
    for _ in range(16): line.append(0); transformed.append(0)
    var active_width = width
    var active_height = height
    for _ in range(levels):
        for x in range(active_width):
            for y in range(active_height): line[y] = plane[y*width+x]
            dwt_line(line,active_height,transformed)
            for y in range(active_height): vertical[y*width+x] = transformed[y]
        for y in range(active_height):
            for x in range(active_width): line[x] = vertical[y*width+x]
            dwt_line(line,active_width,transformed)
            for x in range(active_width): next[y*width+x] = transformed[x]
        for y in range(active_height):
            for x in range(active_width): plane[y*width+x] = next[y*width+x]
        active_width //= 2
        active_height //= 2
    var ordered = List[Int64](capacity=cells)
    var stage = levels
    while stage > 0:
        stage -= 1
        let sw = width >> stage
        let sh = height >> stage
        let hw = sw//2
        let hh = sh//2
        if stage == levels-1:
            for y in range(hh):
                for x in range(hw): ordered.append(plane[y*width+x])
        for y in range(hh):
            for x in range(hw,sw): ordered.append(plane[y*width+x])
        for y in range(hh,sh):
            for x in range(hw): ordered.append(plane[y*width+x])
        for y in range(hh,sh):
            for x in range(hw,sw): ordered.append(plane[y*width+x])
    let bytes = 4*cells
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    for i in range(cells):
        for byte in range(4): output[4*i+byte] = UInt8((ordered[i] >> (8*byte)) & 255)
    return Int64(bytes)
