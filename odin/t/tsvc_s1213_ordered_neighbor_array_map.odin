// Clean-room TSVC s1213 profile; see package rights note.
package tsvc_s1213_ordered_neighbor_array_map
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s1213_ordered_neighbor_array_map :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<13||length>129 do return -1;nr:=input[0];if nr<3||nr>32 do return -1;n:=int(nr);if int(length)!=1+4*n do return -1;var a:[32]i64;var b:[32]i64;var cvec:[32]i64;var d:[32]i64;for i:=0;i<n;i+=1{x:=input[1+i];y:=input[1+n+i];z:=input[1+2*n+i];w:=input[1+3*n+i];if x< -1||x>1||y< -1||y>1||z< -1||z>1||w< -1||w>1 do return -1;a[i]=x;b[i]=y;cvec[i]=z;d[i]=w};if output==nil||capacity<c.size_t(16*n) do return -2;for i:=1;i<n-1;i+=1{a[i]=b[i-1]+cvec[i];b[i]=a[i+1]*d[i]};for i:=0;i<n;i+=1{put64(output,8*i,a[i]);put64(output,8*(n+i),b[i])};return i64(2*n)}
