fn putI64Le(output:[*]u8, offset:usize, value:i64) void {
    const bits:u64=@bitCast(value); for(0..8)|b| output[offset+b]=@truncate(bits>>@intCast(8*b));
}
pub export fn count_distinct_elements_in_window(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64 {
    if(input==null || length<3 || input[0]<1 || input[0]>256)return -1;
    const n:usize=@intCast(input[0]); if(input[1]<1 || input[1]>@as(i64,@intCast(n)) || length!=n+2)return -1;
    const k:usize=@intCast(input[1]); const out_n=n-k+1; const values=input[2..][0..n];
    for(values)|v|{if(v< -2147483648 or v>2147483647)return -1;}
    if(capacity<out_n*8 || output==null)return -2;
    var keys:[256]i32=@splat(0); var counts:[256]i32=@splat(0); var used:usize=0; var distinct:i64=0;
    for(0..k)|i|{const v:@TypeOf(keys[0])=@intCast(values[i]); var j:usize=0;while(j<used and keys[j]!=v):(j+=1){} if(j==used){keys[j]=v;used+=1;} if(counts[j]==0)distinct+=1;counts[j]+=1;}
    putI64Le(output,0,distinct);
    for(k..n)|i|{const incoming:i32=@intCast(values[i]);var j:usize=0;while(j<used and keys[j]!=incoming):(j+=1){}if(j==used){keys[j]=incoming;used+=1;}if(counts[j]==0)distinct+=1;counts[j]+=1;
        const leaving:i32=@intCast(values[i-k]);j=0;while(keys[j]!=leaving):(j+=1){}counts[j]-=1;if(counts[j]==0)distinct-=1;putI64Le(output,(i-k+1)*8,distinct);
    }
    return @intCast(out_n*8);
}
