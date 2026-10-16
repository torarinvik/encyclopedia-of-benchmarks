const max_input_length:usize=4096;
export fn remove_stars(v:[*c]const i64,n:usize,out:[*c]u8,cap:usize)i64{
 if(v==null or n<1 or n>max_input_length+1 or v[0]<0 or v[0]>max_input_length)return -1;const count:usize=@intCast(v[0]);if(n!=count+1)return -1;
 var result:usize=0;for(0..count)|i|{const x=v[i+1];if(x<0 or x>127)return -1;if(x==42){if(result>0)result-=1;}else result+=1;}
 if(result>cap or(result>0 and out==null))return -2;var w:usize=0;for(0..count)|i|{const x=v[i+1];if(x==42){if(w>0)w-=1;}else{out[w]=@intCast(x);w+=1;}}return @intCast(w);
}
