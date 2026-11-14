from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn turn(x: InlineArray[Int64, 32], y: InlineArray[Int64, 32], a: Int, b: Int, c: Int) -> Int64:
    return (x[b]-x[a])*(y[c]-y[a])-(y[b]-y[a])*(x[c]-x[a])

@export("melkman_simple_polyline_hull")
fn melkman_simple_polyline_hull(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 66: return -1
    if input[0] < 3 or input[0] > 32: return -1
    let n = Int(input[0])
    if length != c_size_t(1+2*n): return -1
    var x = InlineArray[Int64, 32](fill=0)
    var y = InlineArray[Int64, 32](fill=0)
    for i in range(n):
        x[i] = input[1+2*i]
        y[i] = input[2+2*i]
        if x[i] < -1000 or x[i] > 1000 or y[i] < -1000 or y[i] > 1000: return -1
    let initial = turn(x,y,0,1,2)
    if initial == 0: return -1
    var deque = InlineArray[Int, 68](fill=0)
    var first = 32
    var last = 35
    deque[32] = 2
    deque[35] = 2
    if initial > 0:
        deque[33] = 0
        deque[34] = 1
    else:
        deque[33] = 1
        deque[34] = 0
    for i in range(3,n):
        if turn(x,y,deque[first],deque[first+1],i) > 0 and turn(x,y,deque[last-1],deque[last],i) > 0: continue
        while last > first and turn(x,y,deque[first],deque[first+1],i) <= 0: first += 1
        if last <= first or first == 0: return -1
        first -= 1
        deque[first] = i
        while last > first and turn(x,y,deque[last-1],deque[last],i) <= 0: last -= 1
        if last <= first or last+1 >= 68: return -1
        last += 1
        deque[last] = i
    let count = last-first
    var start = 0
    for i in range(1,count):
        let a = deque[first+i]
        let b = deque[first+start]
        if x[a] < x[b] or (x[a] == x[b] and y[a] < y[b]): start = i
    let bytes = 8*count
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(bytes): return -2
    var staged = InlineArray[UInt8, 256](fill=0)
    for i in range(count):
        let index = UInt64(deque[first+(start+i)%count])
        for b in range(8): staged[8*i+b] = UInt8((index >> UInt(8*b)) & 255)
    for i in range(bytes): output[i] = staged[i]
    return Int64(bytes)
