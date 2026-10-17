fn storeI32Le(value: u32, output: []u8, offset: usize) void {
    for (0..4) |b| output[offset + b] = @truncate(value >> @intCast(8 * b));
}

export fn subtract(input: ?[*]const i64, length: usize, output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 4) return -2;
    const a=input.?[0..length]; if(a[0]<0 or a[0]>16 or a[1]<0 or a[1]>16)return -2;
    const ra:usize=@intCast(a[0]);const ca:usize=@intCast(a[1]);if(ra==0 and ca!=0)return -2;
    const na=ra*ca;const bd=2+na;if(bd+2>length or a[bd]<0 or a[bd]>16 or a[bd+1]<0 or a[bd+1]>16)return -2;
    const rb:usize=@intCast(a[bd]);const cb:usize=@intCast(a[bd+1]);if(rb==0 and cb!=0)return -2;
    const nb=rb*cb;if(length!=bd+2+nb)return -2;if(ra!=rb or ca!=cb)return -1;
    for(0..na)|i|{if(a[2+i]<-2_147_483_648 or a[2+i]>2_147_483_647 or a[bd+2+i]<-2_147_483_648 or a[bd+2+i]>2_147_483_647)return -2;}
    if(na==0)return 0;if(output==null or output_capacity<na*4)return -3;
    const out=output.?[0..output_capacity];
    for(0..na)|i|{const left:u32=@bitCast(@as(i32,@intCast(a[2+i])));const right:u32=@bitCast(@as(i32,@intCast(a[bd+2+i])));storeI32Le(left-%right,out,i*4);}
    return @intCast(na);
}
