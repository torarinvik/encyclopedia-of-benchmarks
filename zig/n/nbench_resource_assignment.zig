const std=@import("std");
const NMAX:usize=8;
const CELLS:usize=64;
const MAX_ADJUST:usize=2048;
fn first(a:*const [CELLS]i64,mark:*[CELLS]u8,n:usize)usize{
 for(0..n*n)|x|mark[x]=0;var total:usize=0;
 while(true){var made:usize=0;
  for(0..n)|i|{var count:usize=0;var sel:usize=0;for(0..n)|j|{if(a[i*n+j]==0 and mark[i*n+j]==0){count+=1;sel=j;}}if(count==1){made+=1;total+=1;mark[i*n+sel]=1;for(0..n)|k|{if(k!=i and a[k*n+sel]==0)mark[k*n+sel]=2;}}}
  for(0..n)|j|{var count:usize=0;var sel:usize=0;for(0..n)|i|{if(a[i*n+j]==0 and mark[i*n+j]==0){count+=1;sel=i;}}if(count==1){made+=1;total+=1;mark[sel*n+j]=1;for(0..n)|k|{if(k!=j and a[sel*n+k]==0)mark[sel*n+k]=2;}}}
  if(made==0)break;
 }
 if(total==n)return total;
 for(0..n)|i|{var sel=n;for(0..n)|j|{if(a[i*n+j]==0 and mark[i*n+j]==0){sel=j;break;}}if(sel<n){mark[i*n+sel]=1;total+=1;for(0..n)|k|{if(k!=sel and a[i*n+k]==0)mark[i*n+k]=2;}for(0..n)|k|{if(k!=i and a[k*n+sel]==0)mark[k*n+sel]=2;}}}
 return total;
}
fn second(a:*[CELLS]i64,mark:*const [CELLS]u8,n:usize)bool{
 var rows=[_]u8{0}**NMAX;var cols=[_]u8{0}**NMAX;
 for(0..n)|i|{var assigned=false;for(0..n)|j|{if(mark[i*n+j]==1)assigned=true;}rows[i]=if(assigned)0 else 1;}
 while(true){var added:usize=0;for(0..n)|i|{if(rows[i]==1){for(0..n)|j|{if(a[i*n+j]==0)cols[j]=1;}}}for(0..n)|j|{if(cols[j]==1){for(0..n)|i|{if(mark[i*n+j]==1 and rows[i]!=1){rows[i]=1;added+=1;}}}}if(added==0)break;}
 var smallest:i64=std.math.maxInt(i64);for(0..n)|i|{if(rows[i]==1){for(0..n)|j|{if(cols[j]==0 and a[i*n+j]<smallest)smallest=a[i*n+j];}}}if(smallest==std.math.maxInt(i64))return false;
 for(0..n)|i|{for(0..n)|j|{if(rows[i]==1 and cols[j]==0){a[i*n+j]-=smallest;}else if(rows[i]==0 and cols[j]==1){a[i*n+j]+=smallest;}}}return true;
}
export fn nbench_resource_assignment(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
 if(input==null or length<2 or length>66)return -1;const raw=input[0];if(raw<1 or raw>8)return -1;const n:usize=@intCast(raw);if(length!=1+n*n)return -1;
 var a=[_]i64{0}**CELLS;for(0..n*n)|i|{if(input[i+1]<0 or input[i+1]>1000)return -1;a[i]=input[i+1];}
 for(0..n)|i|{var minimum=a[i*n];for(1..n)|j|{if(a[i*n+j]<minimum)minimum=a[i*n+j];}for(0..n)|j|{a[i*n+j]-=minimum;}}
 for(0..n)|j|{var minimum=a[j];for(1..n)|i|{if(a[i*n+j]<minimum)minimum=a[i*n+j];}if(minimum!=0){for(0..n)|i|{a[i*n+j]-=minimum;}}}
 var mark=[_]u8{0}**CELLS;var done=false;for(0..MAX_ADJUST+1)|_|{if(first(&a,&mark,n)==n){done=true;break;}if(!second(&a,&mark,n))return -1;}if(!done)return -1;
 var result=[_]i32{0}**NMAX;var seen=[_]bool{false}**NMAX;
 for(0..n)|i|{var col=n;for(0..n)|j|{if(mark[i*n+j]==1){if(col!=n)return -1;col=j;}}if(col==n or seen[col])return -1;result[i]=@intCast(col);seen[col]=true;}
 const bytes=n*4;if(output==null or capacity<bytes)return -2;for(0..n)|i|{const x:u32=@bitCast(result[i]);for(0..4)|b|{output[4*i+b]=@truncate(x>>@intCast(8*b));}}return @intCast(bytes);
}
