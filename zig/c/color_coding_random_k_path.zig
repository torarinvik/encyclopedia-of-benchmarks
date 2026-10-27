const MaxN=12;const MaxM=66;const MaxK=6;const MaxTrials=8;const MaxInput=232;const MaxOutput=64;
fn put(out:[*]u8,at:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[at+b]=@truncate(bits>>@intCast(8*b));}
fn pathLess(a:[MaxK]i32,b:[MaxK]i32,length:usize)bool{for(0..length)|i|{if(a[i]!=b[i])return a[i]<b[i];}return false;}
export fn color_coding_random_k_path(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
 if(input_opt==null||length<4||length>MaxInput)return -1;const input=input_opt.?;
 if(input[0]<1||input[0]>MaxN||input[1]<0||input[1]>MaxM||input[2]<1||input[2]>MaxK||input[2]>input[0]||input[3]<1||input[3]>MaxTrials)return -1;
 const n:usize=@intCast(input[0]);const m:usize=@intCast(input[1]);const k:usize=@intCast(input[2]);const trials:usize=@intCast(input[3]);const edgeStart:usize=4;const colorStart=edgeStart+2*m;if(length!=colorStart+trials*n)return -1;
 var adj:[MaxN]u16=@splat(0);
 for(0..m)|e|{const av=input[edgeStart+2*e];const bv=input[edgeStart+2*e+1];if(av<0||bv<0||av>=@as(i64,@intCast(n))||bv>=@as(i64,@intCast(n))||av==bv)return -1;const a:usize=@intCast(av);const b:usize=@intCast(bv);if((adj[a]&(@as(u16,1)<<@intCast(b)))!=0)return -1;adj[a]|=@as(u16,1)<<@intCast(b);adj[b]|=@as(u16,1)<<@intCast(a);}
 for(0..trials)|t|{for(0..n)|v|{const color=input[colorStart+t*n+v];if(color<0||color>=@as(i64,@intCast(k)))return -1;}}
 const full=(@as(usize,1)<<@intCast(k))-1;
 for(0..trials)|trial|{
  var colors:[MaxN]usize=@splat(0);for(0..n)|v|colors[v]=@intCast(input[colorStart+trial*n+v]);
  var reachable:[1<<MaxK][MaxN]bool=@splat(@splat(false));var paths:[1<<MaxK][MaxN][MaxK]i32=@splat(@splat(@splat(0)));
  for(0..full+1)|mask|{for(0..n)|v|{for(0..k)|j|{paths[mask][v][j]=-1;}}}
  for(0..n)|v|{const mask=@as(usize,1)<<@intCast(colors[v]);reachable[mask][v]=true;paths[mask][v][0]=@intCast(v);}
  for(1..full+1)|mask|{const pathLen:usize=@intCast(@popCount(@as(u32,@intCast(mask))));for(0..n)|v|{if(!reachable[mask][v]||mask==full)continue;for(0..n)|u|{const colorBit=@as(usize,1)<<@intCast(colors[u]);if((adj[v]&(@as(u16,1)<<@intCast(u)))==0||(mask&colorBit)!=0)continue;const next=mask|colorBit;var candidate:[MaxK]i32=@splat(-1);for(0..pathLen)|j|candidate[j]=paths[mask][v][j];candidate[pathLen]=@intCast(u);if(!reachable[next][u]||pathLess(candidate,paths[next][u],pathLen+1)){reachable[next][u]=true;paths[next][u]=candidate;}}}}
  var best:?usize=null;for(0..n)|v|{if(reachable[full][v]&&(best==null||pathLess(paths[full][v],paths[full][best.?],k))){best=v;}}
  if(best)|end|{const bytes=8*(k+2);if(output_opt==null||capacity<bytes)return -2;var staged:[MaxOutput]u8=@splat(0);put(&staged,0,1);put(&staged,8,@intCast(trial+1));for(0..k)|j|put(&staged,8*(j+2),paths[full][end][j]);@memcpy(output_opt.?[0..bytes],staged[0..bytes]);return @intCast(bytes);}
 }
 if(output_opt==null||capacity<16)return -2;var staged:[16]u8=@splat(0);put(&staged,0,0);put(&staged,8,0);@memcpy(output_opt.?[0..16],staged[0..16]);16
}
