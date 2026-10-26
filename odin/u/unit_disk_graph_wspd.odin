package unit_disk_graph_wspd
import "core:c"
MAX_N :: 8
MAX_PAIRS :: 28
MAX_INPUT :: 18
INF :: i64(2305843009213693951)
Context :: struct { n:int, c:int, count:int, distance:[MAX_N][MAX_N]i64, left:[MAX_PAIRS]u64, right:[MAX_PAIRS]u64 }
Split :: struct { left:u64, right:u64 }
bit_count :: proc(mask0:u64)->int { mask:=mask0; count:=0; for mask!=0 { count+=int(mask&1); mask>>=1 }; return count }
split_mask :: proc(mask:u64)->Split { out:=Split{}; half:=bit_count(mask)/2; seen:=0; for i:=0;i<MAX_N;i+=1 { if mask&(u64(1)<<u32(i))!=0 { if seen<half { out.left|=u64(1)<<u32(i) } else { out.right|=u64(1)<<u32(i) }; seen+=1 } }; return out }
diameter :: proc(x:^Context,mask:u64)->i64 { best:=i64(0); for i:=0;i<x.n;i+=1 { if mask&(u64(1)<<u32(i))!=0 { for j:=i+1;j<x.n;j+=1 { if mask&(u64(1)<<u32(j))!=0&&x.distance[i][j]>best { best=x.distance[i][j] } } } }; return best }
set_distance :: proc(x:^Context,a,b:u64)->i64 { best:=INF; for i:=0;i<x.n;i+=1 { if a&(u64(1)<<u32(i))!=0 { for j:=0;j<x.n;j+=1 { if b&(u64(1)<<u32(j))!=0&&x.distance[i][j]<best { best=x.distance[i][j] } } } }; return best }
cross :: proc(x:^Context,a,b:u64) { da:=diameter(x,a); db:=diameter(x,b); maxd:=da; if db>maxd { maxd=db }; if set_distance(x,a,b)>=i64(x.c)*maxd { if x.count<MAX_PAIRS { x.left[x.count]=a; x.right[x.count]=b; x.count+=1 }; return }; if bit_count(a)>=bit_count(b)&&bit_count(a)>1 { parts:=split_mask(a); cross(x,parts.left,b); cross(x,parts.right,b) } else { parts:=split_mask(b); cross(x,a,parts.left); cross(x,a,parts.right) } }
visit :: proc(x:^Context,mask:u64) { if bit_count(mask)<2 { return }; parts:=split_mask(mask); visit(x,parts.left); visit(x,parts.right); cross(x,parts.left,parts.right) }
put_i64 :: proc(out:[^]u8,at:int,value:i64) { bits:=u64(value); for i:=0;i<8;i+=1 { out[at+i]=u8(bits&255); bits>>=8 } }
@(export)
unit_disk_graph_wspd :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<4||length>MAX_INPUT { return -1 }; n64,c64:=input[0],input[1]; if n64<1||n64>MAX_N||c64<1||c64>8||length!=c.size_t(2+2*int(n64)) { return -1 }; n:=int(n64)
 px:[MAX_N]i64; py:[MAX_N]i64
 for i:=0;i<n;i+=1 { px[i]=input[2+2*i]; py[i]=input[3+2*i]; if px[i]<-8||px[i]>8||py[i]<-8||py[i]>8 { return -1 }; for j:=0;j<i;j+=1 { if px[i]==px[j]&&py[i]==py[j] { return -1 } } }
 x:=Context{n=n,c=int(c64)}
 for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { x.distance[i][j]=if i==j { 0 } else { INF } } }
 for i:=0;i<n;i+=1 { for j:=i+1;j<n;j+=1 { dx:=px[i]-px[j]; dy:=py[i]-py[j]; if dx*dx+dy*dy<=1 { x.distance[i][j]=1; x.distance[j][i]=1 } } }
 for k:=0;k<n;k+=1 { for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { alt:=x.distance[i][k]+x.distance[k][j]; if alt<x.distance[i][j] { x.distance[i][j]=alt } } } }
 for i:=0;i<n;i+=1 { for j:=0;j<n;j+=1 { if x.distance[i][j]>=INF/2 { return -1 } } }
 visit(&x,(u64(1)<<u32(n))-1); bytes:=8+16*x.count; if output==nil||capacity<c.size_t(bytes) { return -2 }; staged:[456]u8; put_i64(&staged[0],0,i64(x.count)); for i:=0;i<x.count;i+=1 { put_i64(&staged[0],8+16*i,i64(x.left[i])); put_i64(&staged[0],16+16*i,i64(x.right[i])) }; for i:=0;i<bytes;i+=1 { output[i]=staged[i] }; return i64(bytes)
}
