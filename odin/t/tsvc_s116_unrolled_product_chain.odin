// Clean-room TSVC s116 profile; see package rights note.
package tsvc_s116_unrolled_product_chain
import "core:c"
put64 :: proc "contextless"(o:[^]u8,p:int,v:i64){b:=u64(v);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
tsvc_s116_unrolled_product_chain :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<8||length>23 do return -1;nr:=input[0];passes:=input[1];if nr<6||nr>21||(nr-1)%5!=0||passes<1||passes>4 do return -1;n:=int(nr);if int(length)!=2+n do return -1;var a:[21]i64;for k:=0;k<n;k+=1{x:=input[2+k];if x != -1&&x != 1 do return -1;a[k]=x};if output==nil||capacity<c.size_t(8*n) do return -2;for _ in 0..<int(passes){i:=0;for i<n-5{a[i]=a[i+1]*a[i];a[i+1]=a[i+2]*a[i+1];a[i+2]=a[i+3]*a[i+2];a[i+3]=a[i+4]*a[i+3];a[i+4]=a[i+5]*a[i+4];i+=5}};for k:=0;k<n;k+=1{put64(output,8*k,a[k])};return i64(n)}
