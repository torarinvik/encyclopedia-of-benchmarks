fn mix(h0:u32,b:u8)u32{return (h0^b)*%16777619;}
fn feed(h0:u32,x:u32)u32{var h=h0;for(0..4)|b|h=mix(h,@truncate(x>>(8*b)));return h;}
export fn pack_consecutive_repetitions_in_sublist(v:[*c]const i64,n:usize)i64{
 if(v==null or n<1 or n>65 or v[0]<0 or v[0]>64 or n!=@as(usize,@intCast(v[0]))+1)return -1;
 const count:usize=@intCast(v[0]);for(0..count)|i|if(v[i+1]< -2147483648 or v[i+1]>2147483647)return -1;
 var h:u32=2166136261;var i:usize=0;while(i<count){const value:i32=@intCast(v[i+1]);var j=i+1;while(j<count and v[j+1]==v[i+1]): (j+=1) {} h=feed(h,@bitCast(value));h=feed(h,@intCast(j-i));i=j;}return @intCast(h);
}
