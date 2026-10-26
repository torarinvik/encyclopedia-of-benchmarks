const N: usize = 8;
const PAIRS: usize = 28;
const INPUT: usize = 18;
const INF: i64 = 2305843009213693951;
const Context = struct { n:usize, c:i64, count:usize, distance:[N][N]i64, pairs:[PAIRS][2]u64 };
const Halves = struct { left:u64, right:u64 };
fn bitCount(mask0:u64)usize{var mask=mask0;var result:usize=0;while(mask!=0):(mask>>=1)result+=@intCast(mask&1);return result;}
fn splitMask(mask:u64)Halves{var out=Halves{.left=0,.right=0};const half=bitCount(mask)/2;var seen:usize=0;for(0..N)|i|{if(mask&(@as(u64,1)<<@intCast(i))!=0){if(seen<half)out.left|=@as(u64,1)<<@intCast(i) else out.right|=@as(u64,1)<<@intCast(i);seen+=1;}}return out;}
fn diameter(x:*const Context,mask:u64)i64{var best:i64=0;for(0..x.n)|i|{if(mask&(@as(u64,1)<<@intCast(i))!=0){for(i+1..x.n)|j|{if(mask&(@as(u64,1)<<@intCast(j))!=0)best=@max(best,x.distance[i][j]);}}}return best;}
fn setDistance(x:*const Context,a:u64,b:u64)i64{var best=INF;for(0..x.n)|i|{if(a&(@as(u64,1)<<@intCast(i))!=0){for(0..x.n)|j|{if(b&(@as(u64,1)<<@intCast(j))!=0)best=@min(best,x.distance[i][j]);}}}return best;}
fn cross(x:*Context,a:u64,b:u64)void{const da=diameter(x,a);const db=diameter(x,b);if(setDistance(x,a,b)>=x.c*@max(da,db)){if(x.count<PAIRS){x.pairs[x.count]=.{a,b};x.count+=1;}return;}if(bitCount(a)>=bitCount(b) and bitCount(a)>1){const halves=splitMask(a);cross(x,halves.left,b);cross(x,halves.right,b);}else{const halves=splitMask(b);cross(x,a,halves.left);cross(x,a,halves.right);}}
fn visit(x:*Context,mask:u64)void{if(bitCount(mask)<2)return;const halves=splitMask(mask);visit(x,halves.left);visit(x,halves.right);cross(x,halves.left,halves.right);}
fn putI64(out:[*]u8,at:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|i|out[at+i]=@truncate(bits>>@intCast(i*8));}
export fn unit_disk_graph_wspd(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<4 or length>INPUT)return -1;const input=input_opt.?;const n64=input[0];const c64=input[1];if(n64<1 or n64>8 or c64<1 or c64>8 or length!=2+2*@as(usize,@intCast(n64)))return -1;const n:usize=@intCast(n64);var px:[N]i64=@splat(0);var py:[N]i64=@splat(0);
 for(0..n)|i|{px[i]=input[2+2*i];py[i]=input[3+2*i];if(px[i]<-8 or px[i]>8 or py[i]<-8 or py[i]>8)return -1;for(0..i)|j|if(px[i]==px[j] and py[i]==py[j])return -1;}
 var x:Context=undefined;x.n=n;x.c=c64;x.count=0;x.pairs=@splat(@splat(0));for(0..n)|i|{for(0..n)|j|x.distance[i][j]=if(i==j)0 else INF;}
 for(0..n)|i|{for(i+1..n)|j|{const dx=px[i]-px[j];const dy=py[i]-py[j];if(dx*dx+dy*dy<=1){x.distance[i][j]=1;x.distance[j][i]=1;}}}
 for(0..n)|k|{for(0..n)|i|{for(0..n)|j|{const alt=x.distance[i][k]+x.distance[k][j];if(alt<x.distance[i][j])x.distance[i][j]=alt;}}}
 for(0..n)|i|{for(0..n)|j|if(x.distance[i][j]>=INF/2)return -1;}
 visit(&x,(@as(u64,1)<<@intCast(n))-1);const bytes=8+16*x.count;if(output_opt==null or capacity<bytes)return -2;var staged:[456]u8=@splat(0);putI64(&staged,0,@intCast(x.count));for(0..x.count)|i|{putI64(&staged,8+16*i,@intCast(x.pairs[i][0]));putI64(&staged,16+16*i,@intCast(x.pairs[i][1]));}const out=output_opt.?;@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes);
}
