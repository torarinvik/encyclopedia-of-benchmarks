const MAX_VALUES:usize=512;
fn choose(values:*const [MAX_VALUES]i64,tree:*const [2*MAX_VALUES+1]i32,left:usize,right:usize)i32{const l=tree[left];const r=tree[right];if(l<0)return r;if(r<0)return l;return if(values[@intCast(l)]<=values[@intCast(r)])l else r;}
fn putI64(out:[*c]u8,offset:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[offset+b]=@truncate(bits>>@intCast(8*b));}
export fn tournament_sort(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<1)return -1;const n64=input[0];if(n64<0 or n64>MAX_VALUES)return -1;const n:usize=@intCast(n64);if(length!=1+n)return -1;var values:[MAX_VALUES]i64=@splat(0);for(0..n)|i|{const v=input[i+1];if(v< -2147483648 or v>2147483647)return -1;values[i]=v;}
 var leaves:usize=1;while(leaves<n)leaves*=2;var tree:[2*MAX_VALUES+1]i32=@splat(-1);for(0..n)|i|tree[leaves+i]=@intCast(i);var node=leaves;while(node>1){node-=1;tree[node]=choose(&values,&tree,node*2,node*2+1);}
 const bytes=(1+n)*8;if(output==null or capacity<bytes)return -2;putI64(output,0,@intCast(n));for(0..n)|out|{const w:usize=@intCast(tree[1]);putI64(output,(1+out)*8,values[w]);var pos=leaves+w;tree[pos]=-1;while(pos>1){pos/=2;tree[pos]=choose(&values,&tree,pos*2,pos*2+1);}}return @intCast(bytes);
}
