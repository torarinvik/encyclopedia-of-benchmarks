fn put(out:[*c]u8,p:usize,x:i64)void{const u:u64=@bitCast(x);for(0..8)|b|out[p+b]=@truncate(u>>@intCast(8*b));}
pub export fn deterministic_line_search(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length!=1)return -1;const target=input[0];if(target==0 or target< -50000 or target>50000)return -1;
 const distance = if (target < 0) -target else target;
 var traveled:i64=0;var leg:i64=0;var depth:i64=1;
 while(true){const negative=leg%2==0;if((target<0)==negative and distance<=depth){traveled+=distance;break;}traveled+=2*depth;depth*=2;leg+=1;}
 if(capacity<16 or output==null)return -2;put(output,0,traveled);put(output,8,leg);return 16;
}
