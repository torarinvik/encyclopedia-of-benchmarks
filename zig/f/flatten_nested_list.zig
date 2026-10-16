export fn flatten_nested_list(v:[*c]const i64,n:usize)i64{
 const open:i64=-9223372036854775808;const close=open+1;
 if(v==null or n==0 or n>255 or v[0]!=open)return -1;var depth:i32=0;var closed=false;var h:u64=0xcbf29ce484222325;
 for(0..n)|i|{const x=v[i];if(x==open){if(closed or (depth==0 and i!=0))return -1;depth+=1;if(depth>16)return -1;}else if(x==close){if(depth==0)return -1;depth-=1;if(depth==0){closed=true;if(i+1!=n)return -1;}}else{if(depth==0 or x< -1000000 or x>1000000)return -1;const u=@as(u64,@bitCast(x));for(0..8)|b|{h=(h^((u>>(8*b))&255))*%0x100000001b3;}}}
 if(depth!=0 or !closed)return -1;return @bitCast(h);
}
