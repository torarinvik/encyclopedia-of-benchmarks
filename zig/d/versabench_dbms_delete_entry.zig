const MAX_WORDS: usize = 181;
fn valid(b: [8]i64) bool { for (0..4) |d| { if (b[d] < -8 or b[d] > 8 or b[4+d] < -8 or b[4+d] > 8 or b[d] >= b[4+d]) return false; } return true; }
fn hit(b: [8]i64, q: [8]i64) bool { for (0..4) |d| { if (q[d] > b[4+d] or b[d] > q[4+d]) return false; } return true; }
fn unionBoxes(bs: [][8]i64) [8]i64 { var out=bs[0]; for(bs[1..])|b|{for(0..4)|d|{out[d]=@min(out[d],b[d]);out[4+d]=@max(out[4+d],b[4+d]);}}return out; }
fn same(a: [8]i64,b: [8]i64) bool { for(0..8)|d|{if(a[d]!=b[d])return false;}return true; }
fn put(out: [*]u8, w: usize, x: i64) void { const u: u64=@bitCast(x); for(0..8)|b|out[w*8+b]=@truncate(u>>@intCast(8*b)); }
export fn versabench_dbms_delete_entry(raw: ?[*]const i64, n: usize, raw_out: ?[*]u8, cap: usize) i64 {
    if(raw==null or n<10 or n>190)return -1;const v=raw.?[0..n];if(v[0]<1 or v[0]>4)return -1;const nc:usize=@intCast(v[0]);var q:[8]i64=undefined;for(0..8)|d|q[d]=v[1+d];if(!valid(q))return -1;
    var boxes:[4][4][8]i64=undefined;var ids:[4][4]i64=undefined;var mbrs:[4][8]i64=undefined;var counts:[4]usize=@splat(0);var seen:[32]bool=@splat(false);var p:usize=9;
    for(0..nc)|c|{if(p+9>n)return -1;const rv=v[p];p+=1;if(rv<1 or rv>4 or p+8+@as(usize,@intCast(rv))*9>n)return -1;counts[c]=@intCast(rv);for(0..8)|d|mbrs[c][d]=v[p+d];p+=8;if(!valid(mbrs[c]))return -1;for(0..counts[c])|r|{for(0..8)|d|boxes[c][r][d]=v[p+d];p+=8;ids[c][r]=v[p];p+=1;if(!valid(boxes[c][r]) or ids[c][r]<0 or ids[c][r]>=32)return -1;const id:usize=@intCast(ids[c][r]);if(seen[id])return -1;seen[id]=true;}if(!same(unionBoxes(boxes[c][0..counts[c]]),mbrs[c]))return -1;}
    if(p!=n)return -1;var kept:[4][4][8]i64=undefined;var kid:[4][4]i64=undefined;var kmbr:[4][8]i64=undefined;var kc:[4]usize=@splat(0);var rem:usize=0;
    for(0..nc)|c|{var k:usize=0;for(0..counts[c])|r|{if(hit(mbrs[c],q) and hit(boxes[c][r],q))continue;kept[c][k]=boxes[c][r];kid[c][k]=ids[c][r];k+=1;}if(k>0){kc[rem]=k;for(0..k)|r|{kept[rem][r]=kept[c][r];kid[rem][r]=kid[c][r];}kmbr[rem]=unionBoxes(kept[rem][0..k]);rem+=1;}}
    var words:[MAX_WORDS]i64=undefined;var w:usize=0;words[w]=@intCast(rem);w+=1;for(0..rem)|c|{words[w]=@intCast(kc[c]);w+=1;for(0..8)|d|{words[w]=kmbr[c][d];w+=1;}for(0..kc[c])|r|{for(0..8)|d|{words[w]=kept[c][r][d];w+=1;}words[w]=kid[c][r];w+=1;}}
    const bytes=w*8;if(raw_out==null or cap<bytes)return -2;const out=raw_out.?;for(0..w)|i|put(out,i,words[i]);return @intCast(bytes);
}
