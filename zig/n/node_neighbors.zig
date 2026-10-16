export fn node_neighbors(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<2 or v[0]<0 or v[0]>64 or v[1]<0 or v[1]>63 or n!=2+2*@as(usize,@intCast(v[0])))return -1;const count:usize=@intCast(v[0]);var seen=[_]bool{false}**64;var buf:[192]u8=undefined;var used:usize=0;
 for(0..count)|i|{const a=v[2+2*i];const b=v[3+2*i];if(a<0 or a>63 or b<0 or b>63)return -1;const x:i64=if(a==v[1])b else if(b==v[1])a else -1;if(x>=0 and !seen[@intCast(x)]){seen[@intCast(x)]=true;if(used>0){buf[used]=',';used+=1;}var y:usize=@intCast(x);if(y>=10){buf[used]='0'+@as(u8,@intCast(y/10));used+=1;y%=10;}buf[used]='0'+@as(u8,@intCast(y));used+=1;}}
 if(used>cap)return -2;@memcpy(out[0..used],buf[0..used]);return @intCast(used);
}
