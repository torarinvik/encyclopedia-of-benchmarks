// Clean-room longest precedence chain of 2-intervals.
const N:usize=16;const F:usize=17;
fn before(v:[*c]const i64,a:usize,b:usize)bool{for(0..4)|q|{const x=v[1+4*a+q];const y=v[1+4*b+q];if(x!=y)return x<y;}return a<b;}
fn precedes(v:[*c]const i64,a:usize,b:usize)bool{return v[1+4*a+1]<v[1+4*b] and v[1+4*a+3]<v[1+4*b+2];}
fn lexless(a:[N]usize,an:usize,b:[N]usize,bn:usize)bool{const m=if(an<bn)an else bn;for(0..m)|i|{if(a[i]!=b[i])return a[i]<b[i];}return an<bn;}
fn put(out:[*]u8,at:usize,x:i64)void{const bits:u64=@bitCast(x);for(0..8)|i|out[at+i]=@truncate(bits>>@intCast(8*i));}
export fn two_interval_precedence_chain(v:[*c]const i64,n:usize,out_opt:?[*]u8,cap:usize)i64{if(v==null||n<5||n>65||v[0]<1||v[0]>16)return -1;const count:usize=@intCast(v[0]);if(n!=1+4*count)return -1;for(0..count)|i|{const p=1+4*i;for(0..4)|q|{if(v[p+q]<0||v[p+q]>63)return -1;}if(v[p]>=v[p+1]||v[p+2]>=v[p+3]||v[p+1]>=v[p+2])return -1;}
 var order:[N]usize=@splat(0);for(0..count)|i|order[i]=i;for(1..count)|i|{const value=order[i];var j=i;while(j>0 and before(v,value,order[j-1])){order[j]=order[j-1];j-=1;}order[j]=value;}
 var paths:[N][N]usize=@splat(@splat(0));var lens:[N]usize=@splat(0);for(0..count)|i|{paths[i][0]=order[i];lens[i]=1;for(0..i)|j|{if(precedes(v,order[j],order[i])){var candidate=paths[j];candidate[lens[j]]=order[i];const m=lens[j]+1;if(m>lens[i] or (m==lens[i] and lexless(candidate,m,paths[i],lens[i]))){paths[i]=candidate;lens[i]=m;}}}}
 var best:usize=0;for(1..count)|i|{if(lens[i]>lens[best] or (lens[i]==lens[best] and lexless(paths[i],lens[i],paths[best],lens[best])))best=i;}var fields:[F]i64=@splat(0);fields[0]=@intCast(lens[best]);for(0..lens[best])|i|fields[i+1]=@intCast(paths[best][i]);const bytes=8*(lens[best]+1);if(out_opt==null or cap<bytes)return -2;const out=out_opt.?;var staged:[F*8]u8=@splat(0);for(0..lens[best]+1)|i|put(&staged,8*i,fields[i]);@memcpy(out[0..bytes],staged[0..bytes]);return @intCast(bytes);}
