// GNU Go 1.1 provenance: Copyright (C) Free Software Foundation, Inc.
// Written by Man L. Li, modified by Wayne Iba, documented by Bob Webber.
// Upstream suicide/eval/countlib/count are under GNU GPL version 1; derivative under GPLv1.
fn groupLiberties(board: [361]u8, start: usize, color: u8) usize {
    var seen = [_]bool{false} ** 361;
    var libSeen = [_]bool{false} ** 361;
    var stack = [_]usize{0} ** 361;
    var top: usize = 1; var total: usize = 0; stack[0] = start; seen[start] = true;
    while (top > 0) {
        top -= 1;
        const at = stack[top]; const r = at / 19; const c = at % 19;
        var nb = [_]usize{0} ** 4; var n: usize = 0;
        if (r > 0) { nb[n] = at - 19; n += 1; }
        if (r < 18) { nb[n] = at + 19; n += 1; }
        if (c > 0) { nb[n] = at - 1; n += 1; }
        if (c < 18) { nb[n] = at + 1; n += 1; }
        for (nb[0..n]) |next| {
            if (board[next] == 0) { if (!libSeen[next]) { libSeen[next] = true; total += 1; } }
            else if (board[next] == color and !seen[next]) { seen[next] = true; stack[top] = next; top += 1; }
        }
    }
    return total;
}

export fn prolangs_c_gnugo_suicide(input: [*]const i64, length: usize) i64 {
    if (length < 6 or length > 246) return -1;
    const row=input[0]; const col=input[1]; const own=input[2]; const opponent=input[3]; const ko=input[4]; const count=input[5];
    if (row < 0 or row >= 19 or col < 0 or col >= 19 or (own != 1 and own != 2) or (opponent != 1 and opponent != 2) or own == opponent or ko < -1 or ko >= 361 or count < 0 or count > 120) return -1;
    if (length != 6 + 2 * @as(usize, @intCast(count))) return -1;
    var board = [_]u8{0} ** 361;
    for (0..@as(usize, @intCast(count))) |k| {
        const at_raw=input[6+2*k]; const stone=input[7+2*k];
        if (at_raw < 0 or at_raw >= 361 or (stone != 1 and stone != 2)) return -1;
        const at: usize=@intCast(at_raw); if (board[at] != 0) return -1; board[at]=@intCast(stone);
    }
    const target: usize=@intCast(row*19+col); if(board[target]!=0)return -1; board[target]=@intCast(opponent);
    if(groupLiberties(board,target,@intCast(opponent))>0)return 0;
    var dead: i64=0;
    for(0..361)|i|{if(board[i]==@as(u8,@intCast(own))&&groupLiberties(board,i,@intCast(own))==0)dead+=1;}
    if(dead==0||(dead==1&&ko==@as(i64,@intCast(target))))return 1;
    return 0;
}
