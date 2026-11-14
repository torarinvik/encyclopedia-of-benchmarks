pub export fn indexed_deque(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input==null or length<1 or length>513 or input[0]<1 or input[0]>256) return -1;
    const q:usize=@intCast(input[0]);
    if (length!=1+2*q) return -1;
    var items:[256]i64=@splat(0); var answers:[256]i64=@splat(0);
    var head:usize=0; var size:usize=0; var count:usize=0;
    for (0..q) |i| {
        const op=input[1+2*i]; const arg=input[2+2*i];
        if (op==0 or op==1) {
            if (arg < -1000000 or arg > 1000000 or size==256) return -1;
            if (op==0) { head=(head+255)%256; items[head]=arg; }
            else { items[(head+size)%256]=arg; }
            size+=1;
        } else if (op==2 or op==3) {
            if (arg!=0 or size==0) return -1;
            if (op==2) head=(head+1)%256;
            size-=1;
        } else if (op==4) {
            if (arg<0 or arg>=@as(i64,@intCast(size))) return -1;
            const index:usize=@intCast(arg);
            answers[count]=items[(head+index)%256]; count+=1;
        } else return -1;
    }
    if (count==0) return -1;
    if (output==null or capacity<8*count) return -2;
    for (0..count) |i| {
        const bits:u64=@bitCast(answers[i]);
        for (0..8) |byte| output[8*i+byte]=@truncate(bits >> @as(u6,@intCast(8*byte)));
    }
    return @intCast(8*count);
}
