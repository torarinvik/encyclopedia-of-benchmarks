const MAX_VERTICES: usize = 8;
const MAX_STATES: usize = 256;
const MAX_INPUT_LENGTH: usize = 65;
export fn hamiltonian_path_exists(input: ?[*]const i64, length: usize) i64 {
    if (length < 1 or length > MAX_INPUT_LENGTH) return -1;
    const values=input orelse return -1;
    if (values[0] < 0 or values[0] > MAX_VERTICES) return -1;
    const n: usize=@intCast(values[0]);
    if (length != 1+n*n) return -1;
    var routes: [MAX_VERTICES]usize = @splat(0);
    for (0..n) |row| { for (0..n) |col| { const cell=values[1+row*n+col]; if (cell!=0 and cell!=1) return -1; if (cell==1) routes[row] |= @as(usize,1)<<@intCast(col); } }
    var dp: [MAX_STATES * MAX_VERTICES]bool = @splat(false);
    for (0..n) |start| dp[(@as(usize,1)<<@intCast(start))*MAX_VERTICES+start]=true;
    const full=(@as(usize,1)<<@intCast(n))-1;
    for (1..(@as(usize,1)<<@intCast(n))) |subset| {
        for (0..n) |last| { if (!dp[subset*MAX_VERTICES+last]) continue; for (0..n) |next| { const bit=@as(usize,1)<<@intCast(next); if ((subset&bit)==0 and (routes[last]&bit)!=0) dp[(subset|bit)*MAX_VERTICES+next]=true; } }
    }
    for (0..n) |last| if (dp[full*MAX_VERTICES+last]) return 1;
    return 0;
}
