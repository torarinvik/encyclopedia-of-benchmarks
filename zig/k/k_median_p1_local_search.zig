const N: usize = 12;
const K: usize = 4;
fn put64(out: [*]u8, at: usize, x: i64) void { const b: u64 = @bitCast(x); for (0..8) |i| out[at+i] = @truncate(b >> @intCast(8*i)); }
fn objective(d: *const [144]i64, n: usize, centers: *const [4]usize, k: usize) i64 { var total: i64 = 0; for (0..n) |i| { var best: i64 = 9223372036854775807; for (0..k) |j| best = @min(best, d[i*N+centers[j]]); total += best; } return total; }
fn sortCenters(c: *[4]usize, k: usize) void { for (1..k) |i| { const x=c[i]; var j=i; while (j>0 and c[j-1]>x) { c[j]=c[j-1]; j-=1; } c[j]=x; } }
fn lexLess(a: *const [4]usize, b: *const [4]usize, k: usize) bool { for (0..k) |i| { if (a[i]!=b[i]) return a[i]<b[i]; } return false; }
export fn k_median_p1_local_search(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 150) return -1;
    const input=input_opt.?; const n64=input[0]; const k64=input[1];
    if (n64<2 or n64>12 or k64<1 or k64>4 or k64>n64 or length != 2 + @as(usize,@intCast(n64*n64+k64))) return -1;
    const n:usize=@intCast(n64); const k:usize=@intCast(k64); var d=[_]i64{0} ** 144; var p:usize=2;
    for (0..n) |i| { for (0..n) |j| { const x=input[p]; p+=1; if (x<0 or x>1000) return -1; d[i*N+j]=x; } }
    for (0..n) |i| { for (0..n) |j| { if (d[i*N+j] != (if(i==j) @as(i64,0) else d[i*N+j]) or d[i*N+j]!=d[j*N+i] or (i!=j and d[i*N+j]==0)) return -1; for (0..n) |h| { if (d[i*N+j]>d[i*N+h]+d[h*N+j]) return -1; } } }
    var selected=[_]bool{false} ** N; var centers=[_]usize{0} ** K;
    for (0..k) |j| { const x=input[p]; p+=1; if (x<0 or x>=n64) return -1; const id:usize=@intCast(x); if(selected[id]) return -1; centers[j]=id; selected[id]=true; }
    sortCenters(&centers,k); var current=objective(&d,n,&centers,k);
    while(true) { var best=current; var bestc=centers; var have=false; for(0..k) |leave| { for(0..n) |enter| { if(selected[enter]) continue; var cand=centers; cand[leave]=enter; sortCenters(&cand,k); const value=objective(&d,n,&cand,k); if(value<current and (value<best or (value==best and (!have or lexLess(&cand,&bestc,k))))){best=value;bestc=cand;have=true;} } } if(!have) break; for(0..k) |i| selected[centers[i]]=false; centers=bestc; for(0..k) |i| selected[centers[i]]=true; current=best; }
    const bytes=8*(2+k); if(output_opt==null or capacity<bytes) return -2; const out=output_opt.?; put64(out,0,current); put64(out,8,@intCast(k)); for(0..k) |i| put64(out,16+8*i,@intCast(centers[i])); return @intCast(bytes);
}
