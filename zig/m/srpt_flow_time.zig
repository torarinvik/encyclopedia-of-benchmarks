fn put64(o:[*]u8,p:usize,x:i64)void{const b:u64=@bitCast(x);for(0..8)|j|o[p+j]=@truncate(b>>@intCast(8*j));}
export fn srpt_flow_time(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null||length<4||length>26)return -1;const input=input_opt.?;const mr=input[0];const nr=input[1];if(mr<1 or mr>4 or nr<1 or nr>12 or length!=2+2*@as(usize,@intCast(nr)))return -1;
 const machines:usize=@intCast(mr);const n:usize=@intCast(nr);var release:[12]i64=@splat(0);var rem:[12]i64=@splat(0);var completion:[12]i64=@splat(0);
 for(0..n)|i|{release[i]=input[2+2*i];rem[i]=input[3+2*i];if(release[i]<0 or release[i]>50 or rem[i]<1 or rem[i]>10)return -1;}
 const bytes=8*(1+n);if(output_opt==null or capacity<bytes)return -2;const output=output_opt.?;var time:i64=0;var done:usize=0;
 while(done<n){var chosen:[12]bool=@splat(false);var selected:[12]usize=@splat(0);var count:usize=0;
  for(0..machines)|_|{var best:usize=n;for(0..n)|i|{if(!chosen[i] and rem[i]>0 and release[i]<=time and (best==n or rem[i]<rem[best] or (rem[i]==rem[best] and i<best)))best=i;}if(best==n)break;chosen[best]=true;selected[count]=best;count+=1;}
  if(count==0){var next:i64=51;for(0..n)|i|{if(rem[i]>0 and release[i]<next)next=release[i];}time=next;}else{time+=1;for(0..count)|j|{const i=selected[j];rem[i]-=1;if(rem[i]==0){completion[i]=time;done+=1;}}}
 }
 var total:i64=0;for(0..n)|i|total+=completion[i]-release[i];put64(output,0,total);for(0..n)|i|put64(output,8*(1+i),completion[i]);return @intCast(bytes);
}
