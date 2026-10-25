const M=8;const E=8;const W=8;const Q=8;
fn ihash(a:[]const i64,m:usize) usize{var h:u32=0;const first=@min(a.len,4);for(a[0..first])|x|{h=(h<<8)|(@as(u32,@intCast(x))-32);}for(a[first..])|x|{h=((h<<5)|(h>>27))^(@as(u32,@intCast(x))-32);}return h%m;}
export fn cbench_ispell_lookup_chain(input:[*c]const i64,len:usize) i64{
 if(input==null or len<3 or len>108)return -1;if(input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8 or input[2]<0 or input[2]>8)return -1;
 const m:usize=@intCast(input[0]);const q:usize=@intCast(input[1]);const n:usize=@intCast(input[2]);if(len<3+q+m+2*n)return -1;
 const h0=3+q;const nx0=h0+m;const l0=nx0+n;var p=l0+n;var heads=[_]i64{-1}**M;var next=[_]i64{-1}**E;var lens=[_]usize{0}**E;var off=[_]usize{0}**E;
 for(0..q)|j|{if(input[3+j]<97 or input[3+j]>122)return -1;}for(0..m)|b|{heads[b]=input[h0+b];if(heads[b]<-1 or heads[b]>=@as(i64,@intCast(n)))return -1;}
 for(0..n)|i|{next[i]=input[nx0+i];const ll=input[l0+i];if(next[i]<-1 or next[i]>=@as(i64,@intCast(n)) or ll<1 or ll>W)return -1;lens[i]=@intCast(ll);if(p+lens[i]>len)return -1;off[i]=p;for(0..lens[i])|j|{if(input[p+j]<97 or input[p+j]>122)return -1;}p+=lens[i];}
 if(p!=len)return -1;var seen=[_]bool{false}**E;var count:usize=0;for(0..m)|b|{var x=heads[b];while(x!=-1){const i:usize=@intCast(x);if(seen[i])return -1;seen[i]=true;count+=1;if(ihash(input[off[i]..off[i]+lens[i]],m)!=b)return -1;x=next[i];}}if(count!=n)return -1;
 const b=ihash(input[3..3+q],m);var x=heads[b];while(x!=-1){const i:usize=@intCast(x);if(lens[i]==q){var equal=true;for(0..q)|j|{if(input[off[i]+j]!=input[3+j])equal=false;}if(equal)return @intCast(i+1);}x=next[i];}return 0;
}
