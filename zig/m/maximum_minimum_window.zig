fn store(x:i64,out:[]u8,pos:usize) void {const bits:u64=@bitCast(x);for(0..8)|b|out[pos+b]=@truncate(bits>>@intCast(8*b));}
export fn maximum_minimum_window(input:?[*]const i64,length:usize,output:?[*]u8,capacity:usize)i64{
 if(input==null or length<2)return -2;const v=input.?[0..length];if(v[0]<1 or v[0]>256 or length!=@as(usize,@intCast(v[0]))+1)return -2;const n:usize=@intCast(v[0]);for(v[1..])|x|{if(x<0 or x>1_000_000)return -2;}if(output==null or capacity<n*8)return -3;
 var stack:[256]usize=undefined;var top:usize=0;var left:[256]isize=undefined;var right:[256]isize=undefined;var ans=[_]i64{0}**257;
 for(0..n)|i|{while(top>0 and v[stack[top-1]+1]>=v[i+1]){top-=1;}left[i]=if(top>0)@intCast(stack[top-1]) else -1;stack[top]=i;top+=1;}
 top=0;var ii=n;while(ii>0){ii-=1;while(top>0 and v[stack[top-1]+1]>=v[ii+1]){top-=1;}right[ii]=if(top>0)@intCast(stack[top-1]) else @intCast(n);stack[top]=ii;top+=1;}
 for(0..n)|i|{const len:usize=@intCast(right[i]-left[i]-1);ans[len]=@max(ans[len],v[i+1]);}var k=n;while(k>1){k-=1;ans[k]=@max(ans[k],ans[k+1]);}
 const out=output.?[0..n*8];for(1..n+1)|i|store(ans[i],out,(i-1)*8);return @intCast(n);
}
