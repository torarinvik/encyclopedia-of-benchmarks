package all_farthest_neighbors_convex
import "core:c"

Point :: struct { x, y: i64 }
score :: proc(points: ^[64]Point, n, row, col: int) -> i64 {
    if col <= row { return i64(col-row) }
    if col >= row+n { return -1 }
    dx := points[row].x-points[col%n].x; dy := points[row].y-points[col%n].y
    return dx*dx+dy*dy
}
maxima :: proc(points: ^[64]Point, n: int, rows, columns: []int, answer: ^[64]int) {
    if len(rows) == 0 { return }
    reduced: [127]int
    count := 0
    for col in columns {
        for count > 0 && score(points,n,rows[count-1],col) > score(points,n,rows[count-1],reduced[count-1]) { count -= 1 }
        if count < len(rows) { reduced[count] = col; count += 1 }
    }
    odd: [32]int
    odd_count := 0
    for i := 1; i < len(rows); i += 2 { odd[odd_count]=rows[i]; odd_count += 1 }
    maxima(points,n,odd[:odd_count],reduced[:count],answer)
    low := 0
    for i := 0; i < len(rows); i += 2 {
        high := count-1
        if i+1 < len(rows) {
            high = low
            for reduced[high] != answer[rows[i+1]] { high += 1 }
        }
        best := low
        for j := low+1; j <= high; j += 1 {
            if score(points,n,rows[i],reduced[j]) > score(points,n,rows[i],reduced[best]) { best = j }
        }
        answer[rows[i]] = reduced[best]; low = high
    }
}
@(export)
all_farthest_neighbors_convex :: proc "c" (input: [^]i64, length: c.size_t,
                                            output: [^]u8, capacity: c.size_t) -> i64 {
    if input == nil || length < 7 || length > 129 || input[0] < 3 || input[0] > 64 { return -1 }
    n := int(input[0])
    if int(length) != 1+2*n { return -1 }
    points: [64]Point
    for i := 0; i < n; i += 1 {
        x,y := input[1+2*i],input[2+2*i]
        if x < -1000000 || x > 1000000 || y < -1000000 || y > 1000000 { return -1 }
        points[i] = Point{x,y}
    }
    for i := 0; i < n; i += 1 {
        a,b,c := points[i],points[(i+1)%n],points[(i+2)%n]
        if (b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0 { return -1 }
    }
    if output == nil || capacity < c.size_t(8*n) { return -2 }
    rows, answer: [64]int
    columns: [127]int
    for i := 0; i < n; i += 1 { rows[i]=i }
    for i := 0; i < 2*n-1; i += 1 { columns[i]=i }
    maxima(&points,n,rows[:n],columns[:2*n-1],&answer)
    for i := 0; i < n; i += 1 {
        index := u64(answer[i]%n)
        for byte := 0; byte < 8; byte += 1 { output[8*i+byte]=u8((index >> u64(8*byte)) & 255) }
    }
    return i64(8*n)
}
