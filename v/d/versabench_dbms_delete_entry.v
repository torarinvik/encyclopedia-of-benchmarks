module versabench_dbms_delete_entry
const max_words=181
fn valid(b [8]i64) bool { for d in 0..4 { if b[d]<-8||b[d]>8||b[4+d]<-8||b[4+d]>8||b[d]>=b[4+d] { return false } }; return true }
fn hit(b [8]i64,q [8]i64) bool { for d in 0..4 { if q[d]>b[4+d]||b[d]>q[4+d] { return false } }; return true }
fn union_boxes(bs [][8]i64) [8]i64 { mut out:=bs[0];for i in 1..bs.len{for d in 0..4{out[d]=min(out[d],bs[i][d]);out[4+d]=max(out[4+d],bs[i][4+d])}};return out }
fn same(a [8]i64,b [8]i64) bool { for i in 0..8 { if a[i]!=b[i] { return false } }; return true }
fn put(out &u8,w int,x i64){u:=u64(x);for b in 0..8{unsafe{out[w*8+b]=u8((u>>u64(8*b))&255)}}}
@[export:'versabench_dbms_delete_entry']
pub fn versabench_dbms_delete_entry(raw &i64,n usize,raw_out &u8,cap usize) i64 {
 unsafe {
  if raw==nil||n<10||n>190{return -1};if raw[0]<1||raw[0]>4{return -1};nc:=int(raw[0]);mut q:=[8]i64{};for d in 0..8{q[d]=raw[1+d]};if !valid(q){return -1}
  mut boxes:=[4][4][8]i64{};mut ids:=[4][4]i64{};mut mbrs:=[4][8]i64{};mut counts:=[4]int{};mut seen:=[32]bool{};mut p:=9
  for c in 0..nc{if p+9>int(n){return -1};rv:=raw[p];p++;if rv<1||rv>4||p+8+int(rv)*9>int(n){return -1};counts[c]=int(rv);for d in 0..8{mbrs[c][d]=raw[p+d]};p+=8;if !valid(mbrs[c]){return -1};for r in 0..counts[c]{for d in 0..8{boxes[c][r][d]=raw[p+d]};p+=8;ids[c][r]=raw[p];p++;if !valid(boxes[c][r])||ids[c][r]<0||ids[c][r]>=32||seen[int(ids[c][r])]{return -1};seen[int(ids[c][r])]=true};if !same(union_boxes(boxes[c][..counts[c]]),mbrs[c]){return -1}}
  if p!=int(n){return -1};mut kept:=[4][4][8]i64{};mut kid:=[4][4]i64{};mut kmbr:=[4][8]i64{};mut kc:=[4]int{};mut rem:=0
  for c in 0..nc{mut k:=0;for r in 0..counts[c]{if hit(mbrs[c],q)&&hit(boxes[c][r],q){continue};kept[c][k]=boxes[c][r];kid[c][k]=ids[c][r];k++};if k>0{kc[rem]=k;for r in 0..k{kept[rem][r]=kept[c][r];kid[rem][r]=kid[c][r]};kmbr[rem]=union_boxes(kept[rem][..k]);rem++}}
  mut words:=[max_words]i64{};mut w:=0;words[w]=i64(rem);w++;for c in 0..rem{words[w]=i64(kc[c]);w++;for d in 0..8{words[w]=kmbr[c][d];w++};for r in 0..kc[c]{for d in 0..8{words[w]=kept[c][r][d];w++};words[w]=kid[c][r];w++}}
  bytes:=w*8;if raw_out==nil||cap<bytes{return -2};for i in 0..w{put(raw_out,i,words[i])};return i64(bytes)
 }
}
