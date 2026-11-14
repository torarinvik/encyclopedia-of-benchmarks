from std.collections import InlineArray, List
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

fn afn_score(xs: InlineArray[Int64, 64], ys: InlineArray[Int64, 64],
             n: Int, row: Int, col: Int) -> Int64:
    if col <= row: return Int64(col-row)
    if col >= row+n: return -1
    let dx = xs[row]-xs[col%n]; let dy = ys[row]-ys[col%n]
    return dx*dx+dy*dy

fn afn_maxima(xs: InlineArray[Int64, 64], ys: InlineArray[Int64, 64], n: Int,
              rows: List[Int], columns: List[Int], mut answer: InlineArray[Int, 64]):
    if len(rows) == 0: return
    var reduced = List[Int]()
    for col in columns:
        while len(reduced) > 0:
            let row = rows[len(reduced)-1]
            if afn_score(xs,ys,n,row,col) <= afn_score(xs,ys,n,row,reduced[len(reduced)-1]): break
            _ = reduced.pop()
        if len(reduced) < len(rows): reduced.append(col)
    var odd = List[Int]()
    var i = 1
    while i < len(rows):
        odd.append(rows[i]); i += 2
    afn_maxima(xs,ys,n,odd,reduced,answer)
    var low = 0
    i = 0
    while i < len(rows):
        var high = len(reduced)-1
        if i+1 < len(rows):
            high = low
            while reduced[high] != answer[rows[i+1]]: high += 1
        var best = low
        for j in range(low+1,high+1):
            if afn_score(xs,ys,n,rows[i],reduced[j]) > afn_score(xs,ys,n,rows[i],reduced[best]): best = j
        answer[rows[i]] = reduced[best]
        low = high; i += 2

@export("all_farthest_neighbors_convex")
fn all_farthest_neighbors_convex(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
                                  output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input == UnsafePointer[Int64, ImmutAnyOrigin]() or length < 7 or length > 129: return -1
    if input[0] < 3 or input[0] > 64: return -1
    let n = Int(input[0])
    if length != c_size_t(1+2*n): return -1
    var xs = InlineArray[Int64, 64](fill=0)
    var ys = InlineArray[Int64, 64](fill=0)
    for i in range(n):
        let x = input[1+2*i]; let y = input[2+2*i]
        if x < -1000000 or x > 1000000 or y < -1000000 or y > 1000000: return -1
        xs[i] = x; ys[i] = y
    for i in range(n):
        let j = (i+1)%n; let k = (i+2)%n
        if (xs[j]-xs[i])*(ys[k]-ys[j])-(ys[j]-ys[i])*(xs[k]-xs[j]) >= 0: return -1
    if output == UnsafePointer[UInt8, MutAnyOrigin]() or capacity < c_size_t(8*n): return -2
    var rows = List[Int](); var columns = List[Int]()
    var answer = InlineArray[Int, 64](fill=0)
    for i in range(n): rows.append(i)
    for i in range(2*n-1): columns.append(i)
    afn_maxima(xs,ys,n,rows,columns,answer)
    for i in range(n):
        let index = answer[i]%n
        for byte in range(8): output[8*i+byte] = UInt8((index >> (8*byte)) & 255)
    return Int64(8*n)
