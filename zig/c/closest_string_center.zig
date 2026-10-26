/// Bounded exact closest-string center by lexicographic exhaustive search.
export fn closest_string_center(x:?[*]const i64,length:usize,out:?[*]u8,cap:usize)i64{
 const a=x orelse return -2;if(length<3 or length>51)return -1;const nv=a[0];const mv=a[1];const qv=a[2];
 if(nv<1 or nv>6 or mv<1 or mv>8 or (qv!=2 and qv!=3))return -1;const n:usize=@intCast(nv);const m:usize=@intCast(mv);const q:usize=@intCast(qv);if(length!=3+n*m)return -1;
 for(3..length)|i|if(a[i]<0 or a[i]>=qv)return -1;var total:usize=1;for(0..m)|_|total*=q;var best=m+1;var bestc:[8]usize=@splat(0);var candidate:[8]usize=@splat(0);
 for(0..total)|code|{var v=code;var p=m;while(p>0){p-=1;candidate[p]=v%q;v/=q;}var radius:usize=0;for(0..n)|row|{var d:usize=0;for(0..m)|col|{if(@as(i64,@intCast(candidate[col]))!=a[3+row*m+col])d+=1;}if(d>radius)radius=d;}if(radius<best){best=radius;for(0..m)|j|bestc[j]=candidate[j];}}
 const bytes=8*(m+1);const dst=out orelse if(bytes>0)return -2 else return 0;if(cap<bytes)return -2;const r:u64=@intCast(best);for(0..8)|b|dst[b]=@truncate(r>>(8*b));for(0..m)|j|{const z:u64=@intCast(bestc[j]);for(0..8)|b|dst[8*(j+1)+b]=@truncate(z>>(8*b));}return @intCast(bytes);
}
