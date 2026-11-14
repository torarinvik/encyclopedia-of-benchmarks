const Point = struct { x: i64 = 0, y: i64 = 0 };
fn score(points: *const [64]Point, n: usize, row: usize, col: usize) i64 {
    if (col <= row) return @as(i64,@intCast(col))-@as(i64,@intCast(row));
    if (col >= row+n) return -1;
    const dx=points[row].x-points[col%n].x; const dy=points[row].y-points[col%n].y;
    return dx*dx+dy*dy;
}
fn maxima(points: *const [64]Point, n: usize, rows: []const usize,
          columns: []const usize, answer: *[64]usize) void {
    if (rows.len == 0) return;
    var reduced: [127]usize = @splat(0); var count: usize = 0;
    for (columns) |col| {
        while (count > 0 and score(points,n,rows[count-1],col) > score(points,n,rows[count-1],reduced[count-1])) count -= 1;
        if (count < rows.len) { reduced[count]=col; count+=1; }
    }
    var odd: [32]usize = @splat(0); var odd_count: usize = 0; var i: usize = 1;
    while (i < rows.len) : (i+=2) { odd[odd_count]=rows[i]; odd_count+=1; }
    maxima(points,n,odd[0..odd_count],reduced[0..count],answer);
    var low: usize = 0; i=0;
    while (i < rows.len) : (i+=2) {
        var high=count-1;
        if (i+1 < rows.len) { high=low; while (reduced[high] != answer[rows[i+1]]) : (high+=1) {} }
        var best=low; var j=low+1;
        while (j<=high) : (j+=1) {
            if (score(points,n,rows[i],reduced[j]) > score(points,n,rows[i],reduced[best])) best=j;
        }
        answer[rows[i]]=reduced[best]; low=high;
    }
}
pub export fn all_farthest_neighbors_convex(input: [*c]const i64, length: usize,
                                            output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 7 or length > 129 or input[0] < 3 or input[0] > 64) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1+2*n) return -1;
    var points: [64]Point = @splat(.{});
    for (0..n) |i| {
        const x=input[1+2*i]; const y=input[2+2*i];
        if (x < -1000000 or x > 1000000 or y < -1000000 or y > 1000000) return -1;
        points[i]=.{.x=x,.y=y};
    }
    for (0..n) |i| {
        const a=points[i]; const b=points[(i+1)%n]; const c=points[(i+2)%n];
        if ((b.x-a.x)*(c.y-b.y)-(b.y-a.y)*(c.x-b.x) >= 0) return -1;
    }
    if (output == null or capacity < 8*n) return -2;
    var rows: [64]usize = @splat(0); var columns: [127]usize = @splat(0); var answer: [64]usize = @splat(0);
    for (0..n) |i| rows[i]=i;
    for (0..2*n-1) |i| columns[i]=i;
    maxima(&points,n,rows[0..n],columns[0..2*n-1],&answer);
    for (0..n) |i| {
        const index: u64 = @intCast(answer[i]%n);
        for (0..8) |byte| output[8*i+byte] = @truncate(index >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*n);
}
