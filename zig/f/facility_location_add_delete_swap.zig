const MAX_INPUT:usize=75;
fn put(out:[*]u8,at:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|i|out[at+i]=@truncate(b>>@intCast(8*i));}
fn lexLess(a:u32,b:u32,m:usize)bool{var i:usize=0;var j:usize=0;while(true){while(i<m and a&(@as(u32,1)<<@intCast(i))==0)i+=1;while(j<m and b&(@as(u32,1)<<@intCast(j))==0)j+=1;if(i==m or j==m)return i==m and j!=m;if(i!=j)return i<j;i+=1;j+=1;}}
fn objective(n:usize,m:usize,d:*[8][8]i64,fee:*[7]i64,mask:u32)i64{var x:i64=0;for(0..m)|j|{if(mask&(@as(u32,1)<<@intCast(j))!=0)x+=fee[j];}for(0..n)|u|{var best:i64=std.math.maxInt(i64);for(0..m)|j|{if(mask&(@as(u32,1)<<@intCast(j))!=0 and d[u][n+j]<best)best=d[u][n+j];}x+=best;}return x;}
const std=@import("std");
fn consider(c:u32,n:usize,m:usize,d:*[8][8]i64,fee:*[7]i64,best:*u32,bestCost:*i64)void{const v=objective(n,m,d,fee,c);if(v<bestCost.* or (v==bestCost.* and lexLess(c,best.*,m))){best.*=c;bestCost.*=v;}}
export fn facility_location_add_delete_swap(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<4 or length>MAX_INPUT)return -1;const input=input_opt.?;const n0=input[0];const m0=input[1];if(n0<1 or m0<1 or n0+m0>8 or n0>7 or m0>7)return -1;const n:usize=@intCast(n0);const m:usize=@intCast(m0);const q=n+m;if(length!=2+q*q+m+1)return -1;
 var d:[8][8]i64=@splat(@splat(0));var fee:[7]i64=@splat(0);var p:usize=2;for(0..q)|i|{for(0..q)|j|{const v=input[p];p+=1;if(v<0 or v>1000)return -1;d[i][j]=v;}}
 for(0..q)|i|{if(d[i][i]!=0)return -1;for(0..q)|j|{if(i!=j and d[i][j]<=0)return -1;if(d[i][j]!=d[j][i])return -1;for(0..q)|k|{if(d[i][j]>d[i][k]+d[k][j])return -1;}}}
 for(0..m)|j|{fee[j]=input[p];p+=1;if(fee[j]<0 or fee[j]>1000)return -1;}const raw=input[p];if(raw<=0 or @as(u64,@intCast(raw))>=(@as(u64,1)<<@intCast(m)))return -1;
 var current:u32=@intCast(raw);var currentCost=objective(n,m,&d,&fee,current);
 for(0..(@as(usize,1)<<@intCast(m)))|_|{var best=current;var bestCost=currentCost;for(0..m)|j|{const bit:u32=@as(u32,1)<<@intCast(j);if(current&bit==0){consider(current|bit,n,m,&d,&fee,&best,&bestCost);}else if(current&~bit!=0){consider(current&~bit,n,m,&d,&fee,&best,&bestCost);for(0..m)|k|{const other:u32=@as(u32,1)<<@intCast(k);if(current&other==0)consider((current&~bit)|other,n,m,&d,&fee,&best,&bestCost);}}}if(bestCost*10>=currentCost*9)break;current=best;currentCost=bestCost;}
 var count:usize=0;for(0..m)|j|{if(current&(@as(u32,1)<<@intCast(j))!=0)count+=1;}const outBytes=8*(2+n+count);if(output_opt==null or capacity<outBytes)return -2;const output=output_opt.?;put(output,0,currentCost);put(output,8,@intCast(count));var at:usize=16;for(0..m)|j|{if(current&(@as(u32,1)<<@intCast(j))!=0){put(output,at,@intCast(j));at+=8;}}
 for(0..n)|u|{var best:usize=0;var dist:i64=std.math.maxInt(i64);for(0..m)|j|{if(current&(@as(u32,1)<<@intCast(j))!=0 and d[u][n+j]<dist){dist=d[u][n+j];best=j;}}put(output,at,@intCast(best));at+=8;}return @intCast(at);
}
