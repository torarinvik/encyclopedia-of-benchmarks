package versabench_dbms_delete_entry
import "core:c"
MAX_WORDS :: 181
valid :: proc "contextless" (b: [8]i64) -> bool { for d:=0;d<4;d+=1{if b[d]<-8||b[d]>8||b[4+d]<-8||b[4+d]>8||b[d]>=b[4+d] do return false};return true }
hit :: proc "contextless" (b,q: [8]i64) -> bool { for d:=0;d<4;d+=1{if q[d]>b[4+d]||b[d]>q[4+d] do return false};return true }
same :: proc "contextless" (a,b: [8]i64) -> bool {for i:=0;i<8;i+=1{if a[i]!=b[i] do return false};return true}
union_boxes :: proc "contextless" (bs: [][8]i64) -> (out: [8]i64) {out=bs[0];for i:=1;i<len(bs);i+=1{for d:=0;d<4;d+=1{if bs[i][d]<out[d] do out[d]=bs[i][d];if bs[i][4+d]>out[4+d] do out[4+d]=bs[i][4+d]}};return}
put :: proc "contextless" (o: [^]u8,w:int,x:i64){u:=u64(x);for b:=0;b<8;b+=1{o[w*8+b]=u8((u>>u64(8*b))&255)}}
@(export,link_name="versabench_dbms_delete_entry")
versabench_dbms_delete_entry :: proc "c" (raw:[^]i64,n:c.size_t,out:[^]u8,cap:c.size_t)->i64 {
 if raw==nil||n<10||n>190 do return -1;if raw[0]<1||raw[0]>4 do return -1;nc:=int(raw[0]);q:[8]i64;for d:=0;d<8;d+=1{q[d]=raw[1+d]};if !valid(q) do return -1
 boxes:[4][4][8]i64;ids:[4][4]i64;mbrs:[4][8]i64;counts:[4]int;seen:[32]bool;p:=9
 for cidx:=0;cidx<nc;cidx+=1{if p+9>int(n) do return -1;rv:=raw[p];p+=1;if rv<1||rv>4||p+8+int(rv)*9>int(n) do return -1;counts[cidx]=int(rv);for d:=0;d<8;d+=1{mbrs[cidx][d]=raw[p+d]};p+=8;if !valid(mbrs[cidx]) do return -1;for r:=0;r<counts[cidx];r+=1{for d:=0;d<8;d+=1{boxes[cidx][r][d]=raw[p+d]};p+=8;ids[cidx][r]=raw[p];p+=1;if !valid(boxes[cidx][r])||ids[cidx][r]<0||ids[cidx][r]>=32||seen[int(ids[cidx][r])] do return -1;seen[int(ids[cidx][r])]=true};actual:=union_boxes(boxes[cidx][:counts[cidx]]);if !same(actual,mbrs[cidx]) do return -1}
 if p!=int(n) do return -1;kept:[4][4][8]i64;kid:[4][4]i64;kmbr:[4][8]i64;kc:[4]int;rem:=0
 for cidx:=0;cidx<nc;cidx+=1{k:=0;for r:=0;r<counts[cidx];r+=1{if hit(mbrs[cidx],q)&&hit(boxes[cidx][r],q) do continue;kept[cidx][k]=boxes[cidx][r];kid[cidx][k]=ids[cidx][r];k+=1};if k>0{kc[rem]=k;for r:=0;r<k;r+=1{kept[rem][r]=kept[cidx][r];kid[rem][r]=kid[cidx][r]};kmbr[rem]=union_boxes(kept[rem][:k]);rem+=1}}
 words:[MAX_WORDS]i64;w:=0;words[w]=i64(rem);w+=1;for cidx:=0;cidx<rem;cidx+=1{words[w]=i64(kc[cidx]);w+=1;for d:=0;d<8;d+=1{words[w]=kmbr[cidx][d];w+=1};for r:=0;r<kc[cidx];r+=1{for d:=0;d<8;d+=1{words[w]=kept[cidx][r][d];w+=1};words[w]=kid[cidx][r];w+=1}}
 bytes:=w*8;if out==nil||cap<c.size_t(bytes) do return -2;for i:=0;i<w;i+=1{put(out,i,words[i])};return i64(bytes)
}
