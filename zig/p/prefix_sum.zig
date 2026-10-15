const MAX_LENGTH: usize = 256;
const HASH_CAPACITY: usize = 1024;
fn storeI64Le(out: [*]u8, offset: usize, value: i64) void { const bits: u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>(8*b)); }
fn hashKey(key:i64)usize{const rem=@mod(key,@as(i64,HASH_CAPACITY));return @intCast(rem);}
fn containsSum(prefix:[]const i64,n:usize,target:i64)bool{var keys:[HASH_CAPACITY]i64=@splat(0);var used:[HASH_CAPACITY]bool=@splat(false);var slot=hashKey(0);used[slot]=true;keys[slot]=0;for(1..n+1)|end|{const wanted=prefix[end]-target;slot=hashKey(wanted);while(used[slot] and keys[slot]!=wanted){slot=(slot+1)%HASH_CAPACITY;}if(used[slot])return true;slot=hashKey(prefix[end]);while(used[slot] and keys[slot]!=prefix[end]){slot=(slot+1)%HASH_CAPACITY;}if(!used[slot]){used[slot]=true;keys[slot]=prefix[end];}}return false;}
export fn prefix_sum(raw:[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
    if(length<2)return -1;const input=raw[0..length];if(input[0]<0 or input[0]>2 or input[1]<0 or input[1]>MAX_LENGTH)return -1;const op=input[0];const n:usize=@intCast(input[1]);const extra:usize=if(op==1)2 else if(op==2)1 else 0;if(length!=2+n+extra or(op==1 and n==0))return -1;
    for(input[2..2+n])|v|{if(v < -2147483648 or v > 2147483647)return -1;}
    if(op==1){const left=input[2+n];const right=input[3+n];if(left<0 or right<left or right>=n)return -1;}else if(op==2 and (input[2+n]<-1_000_000_000_000 or input[2+n]>1_000_000_000_000))return -1;
    var prefix:[MAX_LENGTH+1]i64=@splat(0);for(0..n)|i|{prefix[i+1]=prefix[i]+input[2+i];}const words=if(op==0)n else 1;if(capacity<words*8 or(words>0 and output==null))return -2;
    const out: [*]u8 = if (output) |ptr| ptr else { if(words==0)return 0; return -2; };
    if(op==0){for(0..n)|i|storeI64Le(out,i*8,prefix[i+1]);return @intCast(n);}const result:i64=if(op==1)prefix[@intCast(input[3+n]+1)]-prefix[@intCast(input[2+n])] else @intFromBool(containsSum(prefix[0..n+1],n,input[2+n]));storeI64Le(out,0,result);return 1;
}
