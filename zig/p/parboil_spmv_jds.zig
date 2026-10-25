const N=8; const Z=64; const OUT=36;
fn decode(v:i64) f32{return @as(f32,@floatFromInt(v))/1_000_000.0;}
fn put32(o:[*]u8,p:usize,x:u32) void {o[p]=@truncate(x);o[p+1]=@truncate(x>>8);o[p+2]=@truncate(x>>16);o[p+3]=@truncate(x>>24);}
export fn parboil_spmv_jds(input:[*c]const i64,len:usize,output:[*c]u8,cap:usize) i64{
 if(input==null or len<3 or len>164)return -1;if(input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8 or input[2]<1 or input[2]>64)return -1;
 const n:usize=@intCast(input[0]);const d:usize=@intCast(input[1]);const z:usize=@intCast(input[2]);if(len!=4+3*n+d+2*z)return -1;
 var row=[_]i64{0}**N;var perm=[_]i64{0}**N;var ptr=[_]i64{0}**(N+1);var col=[_]i64{0}**Z;var dat=[_]i64{0}**Z;var vec=[_]i64{0}**N;var p:usize=3;
 for(0..n)|i|{if(input[p]<0 or input[p]>@as(i64,@intCast(d)))return -1;row[i]=input[p];p+=1;}if(row[0]!=@as(i64,@intCast(d)))return -1;for(1..n)|i|{if(row[i]>row[i-1])return -1;}
 for(0..n)|i|{perm[i]=input[p];p+=1;}for(0..n)|i|{if(perm[i]<0 or perm[i]>=@as(i64,@intCast(n)))return -1;for(0..i)|j|{if(perm[i]==perm[j])return -1;}}
 for(0..d+1)|k|{ptr[k]=input[p];p+=1;}for(0..z)|j|{col[j]=input[p];p+=1;}for(0..z)|j|{dat[j]=input[p];p+=1;}for(0..n)|i|{vec[i]=input[p];p+=1;}
 if(ptr[0]!=0)return -1;var off:usize=0;for(0..d)|k|{var count:usize=0;for(0..n)|i|{if(row[i]>@as(i64,@intCast(k)))count+=1;}off+=count;if(ptr[k+1]!=@as(i64,@intCast(off)))return -1;}if(off!=z)return -1;
 for(0..z)|j|{if(col[j]<0 or col[j]>=@as(i64,@intCast(n)) or dat[j]<-1_000_000 or dat[j]>1_000_000)return -1;}for(0..n)|i|{if(vec[i]<-1_000_000 or vec[i]>1_000_000)return -1;}
 if(output==null or cap<4+4*n)return -2;var y=[_]f32{0}**N;var stage=[_]u8{0}**OUT;
 for(0..n)|i|{var acc:f32=0;for(0..@as(usize,@intCast(row[i])))|k|{const j=@as(usize,@intCast(ptr[k]))+i;const prod=decode(dat[j])*decode(vec[@intCast(col[j])]);acc=acc+prod;}y[@intCast(perm[i])]=acc;}
 put32(&stage,0,@intCast(n));for(0..n)|i|{put32(&stage,4+4*i,@bitCast(y[i]));}for(0..4+4*n)|i|{output[i]=stage[i];}return @intCast(4+4*n);
}
