const N:usize=6;const F:usize=7;const MAX_INPUT:usize=17;
fn absF(x:f64)f64{return if(x<0)-x else x;}
fn put(out:[*]u8,at:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[at+b]=@truncate(bits>>@intCast(8*b));}
export fn wire_sizing(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null or length<7 or length>MAX_INPUT)return -1;const input=input_opt.?;const n64=input[0];if(n64<1 or n64>6)return -1;const n:usize=@intCast(n64);const l=input[1];const rd=input[2];const cl=input[3];const r0=input[4];if(l<1 or l>1000 or rd<1 or rd>1000 or cl<1 or cl>1000 or r0<1 or r0>1000 or length!=5+2*n)return -1;
 var h:[N]i64=@splat(0);var c:[N]i64=@splat(0);for(0..n)|i|{h[i]=input[5+i];c[i]=input[5+n+i];if(h[i]<1 or h[i]>32 or c[i]<1 or c[i]>1000 or (i>0 and h[i]>=h[i-1]) or (i>0 and c[i]>=c[i-1]))return -1;}
 var phi:[N][N]f64=@splat(@splat(0));var rho:[N]f64=@splat(0);for(0..n)|i|{rho[i]=@as(f64,@floatFromInt(rd))*@as(f64,@floatFromInt(c[i]))+@as(f64,@floatFromInt(cl))*@as(f64,@floatFromInt(r0))/@as(f64,@floatFromInt(h[i]));for(0..n)|j|{const lo=@min(i,j);const hi=@max(i,j);phi[i][j]=@as(f64,@floatFromInt(r0))*@as(f64,@floatFromInt(c[hi]))/@as(f64,@floatFromInt(h[lo]));}}
 var best:f64=1.0e300;var best_l:[N]f64=@splat(0);var found=false;const limit:usize=@as(usize,1)<<@intCast(n);
 for(1..limit)|mask|{var ids:[N]usize=@splat(0);var k:usize=0;for(0..n)|i|{if(mask&(@as(usize,1)<<@intCast(i))!=0){ids[k]=i;k+=1;}}var a:[N+1][N+2]f64=@splat(@splat(0));
  for(0..k)|r|{for(0..k)|q|a[r][q]=phi[ids[r]][ids[q]];a[r][k]=1;a[r][k+1]= -rho[ids[r]];}for(0..k)|q|a[k][q]=1;a[k][k+1]=@floatFromInt(l);
  var ok=true;for(0..k+1)|col|{var pivot=col;for(col+1..k+1)|r|{if(absF(a[r][col])>absF(a[pivot][col]))pivot=r;}if(absF(a[pivot][col])<1.0e-12){ok=false;break;}if(pivot!=col){for(col..k+2)|q|{const t=a[col][q];a[col][q]=a[pivot][q];a[pivot][q]=t;}}const div=a[col][col];for(col..k+2)|q|a[col][q]/=div;for(0..k+1)|r|{if(r!=col){const factor=a[r][col];for(col..k+2)|q|a[r][q]-=factor*a[col][q];}}}
  if(!ok)continue;var x:[N]f64=@splat(0);for(0..k)|r|x[ids[r]]=a[r][k+1];const lambda=a[k][k+1];var total:f64=0;for(0..n)|i|{if(x[i]< -1.0e-8)ok=false;total+=x[i];var grad=rho[i]+lambda;for(0..n)|j|grad+=phi[i][j]*x[j];if(mask&(@as(usize,1)<<@intCast(i))==0 and grad< -1.0e-7)ok=false;}if(absF(total-@as(f64,@floatFromInt(l)))>1.0e-7)ok=false;if(!ok)continue;
  var obj=@as(f64,@floatFromInt(rd*cl));for(0..n)|i|{obj+=rho[i]*x[i];for(0..n)|j|obj+=0.5*x[i]*phi[i][j]*x[j];}if(!found or obj<best-1.0e-7){found=true;best=obj;best_l=x;}
 }
 if(!found)return -1;var fields:[F]i64=@splat(0);fields[0]=@intFromFloat(@floor(best*1.0e6+0.5));for(0..n)|i|fields[i+1]=@intFromFloat(@floor(@max(0.0,best_l[i])*1.0e6+0.5));const bytes=8*(n+1);if(output_opt==null or capacity<bytes)return -2;var staged:[8*F]u8=@splat(0);for(0..n+1)|i|put(&staged,8*i,fields[i]);const out=output_opt.?;@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes);
}
