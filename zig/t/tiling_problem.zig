const MAX_SIZE = 16;
fn fill(board: *[256]i32, width: usize, row: usize, col: usize, mr: usize, mc: usize, tile: *i32) void {
    if (width == 1) return;
    const h=width/2;const t=tile.*;tile.*+=1;
    const qr=[_]usize{row,row,row+h,row+h};const qc=[_]usize{col,col+h,col,col+h};
    const cr=[_]usize{row+h-1,row+h-1,row+h,row+h};const cc=[_]usize{col+h-1,col+h,col+h-1,col+h};
    const missing=if(mr<row+h)(if(mc<col+h)@as(usize,0)else 1)else if(mc<col+h)@as(usize,2)else 3;
    for(0..4)|q|{var nr=mr;var nc=mc;if(q!=missing){board[cr[q]*MAX_SIZE+cc[q]]=t;nr=cr[q];nc=cc[q];}fill(board,h,qr[q],qc[q],nr,nc,tile);}
}
export fn tiling_problem(v: [*c]const i64,n: usize,out: [*c]u8,cap: usize) i64 {
    if(v==null or n!=3)return -1;const s=v[0];if(s<1 or s>MAX_SIZE or (s&(s-1))!=0 or v[1]<0 or v[1]>=s or v[2]<0 or v[2]>=s)return -1;
    const size:usize=@intCast(s);var board:[256]i32=@splat(0);var tile:i32=1;fill(&board,size,0,0,@intCast(v[1]),@intCast(v[2]),&tile);
    const bytes=size*size*4;if(out==null or cap<bytes)return -2;for(0..size*size)|i|{const x=@as(u32,@bitCast(board[(i/size)*MAX_SIZE+i%size]));for(0..4)|b|out[i*4+b]=@truncate(x>>(8*b));}return @intCast(bytes);
}
