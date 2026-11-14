module all_farthest_neighbors_convex

struct Point { x i64; y i64 }
fn score(points [64]Point, n int, row int, col int) i64 {
    if col <= row { return i64(col-row) }
    if col >= row+n { return -1 }
    dx := points[row].x-points[col%n].x; dy := points[row].y-points[col%n].y
    return dx*dx+dy*dy
}
fn maxima(points [64]Point, n int, rows []int, columns []int, mut answer [64]int) {
    if rows.len == 0 { return }
    mut reduced := []int{}
    for col in columns {
        for reduced.len > 0 && score(points,n,rows[reduced.len-1],col) > score(points,n,rows[reduced.len-1],reduced[reduced.len-1]) { _ = reduced.pop() }
        if reduced.len < rows.len { reduced << col }
    }
    mut odd := []int{}
    for i := 1; i < rows.len; i += 2 { odd << rows[i] }
    maxima(points,n,odd,reduced,mut answer)
    mut low := 0
    for i := 0; i < rows.len; i += 2 {
        mut high := reduced.len-1
        if i+1 < rows.len { high=low; for reduced[high] != answer[rows[i+1]] { high++ } }
        mut best := low
        for j := low+1; j <= high; j++ {
            if score(points,n,rows[i],reduced[j]) > score(points,n,rows[i],reduced[best]) { best=j }
        }
        answer[rows[i]]=reduced[best]; low=high
    }
}
@[export: 'all_farthest_neighbors_convex']
fn all_farthest_neighbors_convex(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if isnil(input) || length < 7 || length > 129 || input[0] < 3 || input[0] > 64 { return -1 }
        n := int(input[0])
        if length != usize(1+2*n) { return -1 }
        mut points := [64]Point{}
        for i in 0 .. n {
            x := input[1+2*i]; y := input[2+2*i]
            if x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000 { return -1 }
            points[i]=Point{x,y}
        }
        for i in 0 .. n {
            a:=points[i]; b:=points[(i+1)%n]; c:=points[(i+2)%n]
            if (b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0 { return -1 }
        }
        if isnil(output) || capacity < usize(8*n) { return -2 }
        mut rows:=[]int{}; mut columns:=[]int{}; mut answer:=[64]int{}
        for i in 0 .. n { rows << i }
        for i in 0 .. 2*n-1 { columns << i }
        maxima(points,n,rows,columns,mut answer)
        for i in 0 .. n {
            index:=u64(answer[i]%n)
            for byte in 0 .. 8 { output[8*i+byte]=u8((index >> (8*byte)) & 255) }
        }
        return i64(8*n)
    }
}
