/// Bounded exact closest-substring center by lexicographic exhaustive search.
export fn closest_substring_center(x:?[*]const i64,length:usize,out:?[*]u8,cap:usize)i64{
 const a=x orelse return -2;if(length<4 or length>44)return -1;const nv=a[0];const mv=a[1];const lv=a[2];const qv=a[3];if(nv<1 or nv>4 or mv<1 or mv>10 or lv<1 or lv>8 or lv>mv or (qv!=2 and qv!=3))return -1;
 const n:usize=@intCast(nv);const m:usize=@intCast(mv);const l:usize=@intCast(lv);const q:usize=@intCast(qv);if(length!=4+n*m)return -1;for(4..length)|i|if(a[i]<0 or a[i]>=qv)return -1;
 var total:usize=1;for(0..l)|_|total*=q;var best=l+1;var bc:[8]usize=@splat(0);var cand:[8]usize=@splat(0);
 for(0..total)|code|{var v=code;var p=l;while(p>0){p-=1;cand[p]=v%q;v/=q;}var radius:usize=0;for(0..n)|row|{var rb=l+1;for(0..m-l+1)|st|{var d:usize=0;for(0..l)|j|if(@as(i64,@intCast(cand[j]))!=a[4+row*m+st+j]){d+=1;};if(d<rb)rb=d;}if(rb>radius)radius=rb;}if(radius<best){best=radius;for(0..l)|j|bc[j]=cand[j];}}
 const bytes=8*(l+1);const dst=out orelse return -2;if(cap<bytes)return -2;var z:u64=@intCast(best);for(0..8)|b|dst[b]=@truncate(z>>(8*b));for(0..l)|j|{z=@intCast(bc[j]);for(0..8)|b|dst[8*(j+1)+b]=@truncate(z>>(8*b));}return @intCast(bytes);
}
