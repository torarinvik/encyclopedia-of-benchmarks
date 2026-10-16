const MAX_ROW: i64 = 30;
const MOD: i64 = 1000000007;
export fn pascal_triangle_ii(row: i64) i64 {
    if (row < 0 or row > MAX_ROW) return -9223372036854775808;
    var triangle: [31][31]i64 = [_][31]i64{[_]i64{0} ** 31} ** 31;
    triangle[0][0] = 1;
    var i: usize = 1; const r: usize = @intCast(row);
    while (i <= r) : (i += 1) { triangle[i][0] = 1; triangle[i][i] = 1; var j: usize = 1; while (j < i) : (j += 1) triangle[i][j] = triangle[i-1][j-1] + triangle[i-1][j]; }
    var hash: i64 = 0; var j: usize = 0; while (j <= r) : (j += 1) hash = @mod(hash * 31 + triangle[r][j], MOD); return hash;
}
