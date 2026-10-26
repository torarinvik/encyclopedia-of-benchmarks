// Clean-room TSVC s233/s2233 profiles; see package rights note.
package tsvc_s233_s2233_matrix_prefix
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for k:=0;k<8;k+=1{o[p+k]=u8(b&255);b>>=8}}
@(export)
tsvc_s233_s2233_matrix_prefix :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<14||length>194 do return -1;nr:=input[0];mode:=input[1];if nr<2||nr>8||(mode!=0&&mode!=1) do return -1;n:=int(nr);nn:=n*n;if int(length)!=2+3*nn do return -1;var a:[64]i64;var b:[64]i64;var cvec:[64]i64;for k:=0;k<nn;k+=1{x:=input[2+k];y:=input[2+nn+k];z:=input[2+2*nn+k];if x< -1||x>1||y< -1||y>1||z< -1||z>1 do return -1;a[k]=x;b[k]=y;cvec[k]=z};if output==nil||capacity<c.size_t(16*nn) do return -2;for i:=1;i<n;i+=1{for j:=1;j<n;j+=1{a[j*n+i]=a[(j-1)*n+i]+cvec[j*n+i]}};if mode==0{for i:=1;i<n;i+=1{for j:=1;j<n;j+=1{b[j*n+i]=b[j*n+i-1]+cvec[j*n+i]}}}else{for i:=1;i<n;i+=1{for j:=1;j<n;j+=1{b[i*n+j]=b[(i-1)*n+j]+cvec[i*n+j]}}};for k:=0;k<nn;k+=1{put64(output,8*k,a[k]);put64(output,8*(nn+k),b[k])};return i64(2*nn)}
