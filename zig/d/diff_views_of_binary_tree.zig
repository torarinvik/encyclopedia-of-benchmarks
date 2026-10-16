const N: usize = 1023;
export fn diff_views_of_binary_tree(a: [*]const i64, n: usize, root: i64, view: i64, out: [*]i64, cap: usize) i64 {
 if(n > N or view < 0 or view > 3)return -1;if(n == 0)return if(root  ==  -1) 0 else -1;
 if(root < 0 or @as(u64,@intCast(root)) >= n)return -1;if(cap < n)return -2;const rr:usize=@intCast(root);
 var parents: [N]usize = @splat(0);
 for(0..n)|i|{const v=a[3*i];const l=a[3*i+1];const r=a[3*i+2];if(v <  -2147483648 or v > 2147483647 or l <  -1 or r <  -1 or (l >= 0 and @as(u64,@intCast(l)) >= n) or (r >= 0 and @as(u64,@intCast(r)) >= n))return -1;if(l >= 0){const x:usize=@intCast(l);parents[x]+=1;if(parents[x] > 1)return -1;}if(r >= 0){const x:usize=@intCast(r);parents[x]+=1;if(parents[x] > 1)return -1;}}
 if(parents[rr] != 0)return -1;for(0..n)|i|{if(i != rr and parents[i] != 1)return -1;}
 var q: [N]usize = @splat(0);var depth: [N]usize = @splat(0);var col: [N]i64 = @splat(0);var seen: [N]bool = @splat(false);var fd: [N]i64 = @splat(std.math.minInt(i64));var ld = fd;var fc: [2 * N + 1]i64 = @splat(std.math.minInt(i64));var lc = fc;
 var head:usize=0;var tail:usize=1;var maxd:usize=0;var minc:i64=0;var maxc:i64=0;q[0]=rr;seen[rr]=true;
 while(head < tail){const u=q[head];head+=1;const d=depth[u];const c=col[u];const v=a[3*u];maxd=@max(maxd,d);minc=@min(minc,c);maxc=@max(maxc,c);const s:usize=@intCast(c+N);if(fd[d] == std.math.minInt(i64))fd[d]=v;ld[d]=v;if(fc[s] == std.math.minInt(i64))fc[s]=v;lc[s]=v;const l=a[3*u+1];const r=a[3*u+2];if(l >= 0){const x:usize=@intCast(l);if(seen[x])return -1;seen[x]=true;depth[x]=d+1;col[x]=c-1;q[tail]=x;tail+=1;}if(r >= 0){const x:usize=@intCast(r);if(seen[x])return -1;seen[x]=true;depth[x]=d+1;col[x]=c+1;q[tail]=x;tail+=1;}}
 if(tail != n)return -1;var w:usize=0;if(view < 2){for(0..maxd+1)|d|{const v=if(view == 0)ld[d] else fd[d];if(v != std.math.minInt(i64)){out[w]=v;w+=1;}}}else{var c=minc;while(c <= maxc):(c+=1){const s:usize=@intCast(c+N);const v=if(view == 2)fc[s] else lc[s];if(v != std.math.minInt(i64)){out[w]=v;w+=1;}}}return @intCast(w);
}
const std=@import("std");
