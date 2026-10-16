module diff_views_of_binary_tree
const nmax = 1023
@[export: 'diff_views_of_binary_tree']
pub fn diff_views_of_binary_tree(a &i64, n usize, root i64, view i64, out &i64, cap usize) i64 {
 if n > nmax || view < 0 || view > 3 { return -1 }
 if n == 0 { if root == -1 { return 0 }; return -1 }
 if root < 0 || u64(root) >= u64(n) { return -1 }
 if cap < n { return -2 }
 unsafe {
  mut parents := [nmax]int{}
  for i in 0 .. int(n) {
   v:=a[3*i]; l:=a[3*i+1]; r:=a[3*i+2]
   if v < -2147483648 || v > 2147483647 || l < -1 || r < -1 || (l>=0 && u64(l)>=u64(n)) || (r>=0 && u64(r)>=u64(n)) { return -1 }
   if l>=0 { parents[int(l)]++; if parents[int(l)]>1{return -1} }
   if r>=0 { parents[int(r)]++; if parents[int(r)]>1{return -1} }
  }
  rr:=int(root); if parents[rr]!=0{return -1}; for i in 0..int(n){if (i != rr) && (parents[i] != 1){return -1}}
  mut q:=[nmax]int{}; mut depth:=[nmax]int{}; mut col:=[nmax]int{}; mut seen:=[nmax]bool{}
  mut fd:=[nmax]i64{};mut ld:=[nmax]i64{};mut fc:=[2*nmax+1]i64{};mut lc:=[2*nmax+1]i64{}
  sentinel:=i64(-9223372036854775807)
  for i in 0..nmax {fd[i]=sentinel;ld[i]=sentinel};for i in 0..(2*nmax+1){fc[i]=sentinel;lc[i]=sentinel}
  mut head:=0;mut tail:=1;mut maxd:=0;mut minc:=0;mut maxc:=0;q[0]=rr;seen[rr]=true
  for head<tail {u:=q[head];head++;d:=depth[u];c:=col[u];value:=a[3*u];if d>maxd{maxd=d};if c<minc{minc=c};if c>maxc{maxc=c};s:=c+nmax;if fd[d]==sentinel{fd[d]=value};ld[d]=value;if fc[s]==sentinel{fc[s]=value};lc[s]=value
   l:=a[3*u+1];r:=a[3*u+2]
   if l>=0{x:=int(l);if seen[x]||tail>=int(n){return -1};seen[x]=true;depth[x]=d+1;col[x]=c-1;q[tail]=x;tail++}
   if r>=0{x:=int(r);if seen[x]||tail>=int(n){return -1};seen[x]=true;depth[x]=d+1;col[x]=c+1;q[tail]=x;tail++}
  }
  if tail!=int(n){return -1};mut w:=0
  if view<2{for d in 0..maxd+1{mut v:=fd[d];if view==0{v=ld[d]};if v!=sentinel{out[w]=v;w++}}}else{for c in minc..maxc+1{mut v:=fc[c+nmax];if view==3{v=lc[c+nmax]};if v!=sentinel{out[w]=v;w++}}}
  return i64(w)
 }
}
