const MAX_LENGTH: usize=12;
const OUT_CAP: usize=16000;
const Context=struct{text:[MAX_LENGTH]i64,length:usize,ends:[MAX_LENGTH]usize,result:[OUT_CAP]i64,used:usize,partitions:usize};

fn isPalindrome(ctx:*const Context,start:usize,end:usize)bool{var left=start;var right=end;while(left<right):(left+=1){if(ctx.text[left]!=ctx.text[right-1])return false;right-=1;}return true;}
fn enumerate(ctx:*Context,start:usize,depth:usize)void{
    if(start==ctx.length){ctx.partitions+=1;ctx.result[ctx.used]=@intCast(depth);ctx.used+=1;for(0..depth)|i|{ctx.result[ctx.used]=@intCast(ctx.ends[i]);ctx.used+=1;}return;}
    for(start+1..ctx.length+1)|end|{if(isPalindrome(ctx,start,end)){ctx.ends[depth]=end;enumerate(ctx,end,depth+1);}}
}

pub export fn palindrome_partitioning_all_partitions(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if(input==null or length<1 or input[0]<0 or input[0]>@as(i64,@intCast(MAX_LENGTH)) or length!=@as(usize,@intCast(input[0]))+1)return -1;
    const n:usize=@intCast(input[0]);var ctx=Context{.text=[_]i64{0}**MAX_LENGTH,.length=n,.ends=[_]usize{0}**MAX_LENGTH,.result=[_]i64{0}**OUT_CAP,.used=1,.partitions=0};
    for(0..n)|i|{if(input[i+1]<0 or input[i+1]>127)return -1;ctx.text[i]=input[i+1];}
    enumerate(&ctx,0,0);ctx.result[0]=@intCast(ctx.partitions);
    const required=ctx.used*8;if(output==null or capacity<required)return -2;
    for(0..ctx.used)|i|{const bits:u64=@bitCast(ctx.result[i]);for(0..8)|byte|output[i*8+byte]=@truncate(bits>>@intCast(8*byte));}
    return @intCast(required);
}
