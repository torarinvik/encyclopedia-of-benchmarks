export fn elementary(v:?[*]const i64,n:usize,out:[*c]u8,capacity:usize)i64{
 if(v==null or n<2 or n>129)return -1;const a=v.?;const count=a[0];if(count<1 or count>128 or n!=@as(usize,@intCast(count))+1 or a[1]!=0)return -1;
 for(1..n)|i|{if(a[i]!=0 and a[i]!=1)return -1;}const len:usize=@intCast(count);if(capacity<len or out==null)return -2;
 for(0..len)|i|{const l:u32=if(i>0) @intCast(a[i]) else 0;const c:u32=@intCast(a[i+1]);const r:u32=if(i+1<len) @intCast(a[i+2]) else 0;out[i]=@truncate((30>>(l*4+c*2+r))&1);}
 return count;
}
