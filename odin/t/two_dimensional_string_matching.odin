package two_dimensional_string_matching
import "core:c"
MAX_INPUT :: 132
put64 :: proc(o:[^]u8,p:int,x:i64){b:=u64(x);for j:=0;j<8;j+=1{o[p+j]=u8(b&255);b>>=8}}
@(export)
two_dimensional_string_matching :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<6||length>MAX_INPUT do return -1;rr:=input[0];cc:=input[1];hr:=input[2];wc:=input[3];if rr<1||rr>8||cc<1||cc>8||hr<1||hr>rr||wc<1||wc>cc do return -1;r:=int(rr);c:=int(cc);h:=int(hr);w:=int(wc);if length!=c.size_t(4+r*c+h*w) do return -1
 text:[64]i64;pat:[64]i64;p:=4
 for i:=0;i<r*c;i+=1{text[i]=input[p];p+=1;if text[i]<0||text[i]>3 do return -1};for i:=0;i<h*w;i+=1{pat[i]=input[p];p+=1;if pat[i]<0||pat[i]>3 do return -1}
 prefix:[8]i64;for i:=1;i<h;i+=1{q:=int(prefix[i-1]);for q>0{equal:=true;for j:=0;j<w;j+=1{if pat[i*w+j]!=pat[q*w+j]{equal=false}};if equal{break};q=int(prefix[q-1])};equal:=true;for j:=0;j<w;j+=1{if pat[i*w+j]!=pat[q*w+j]{equal=false}};if equal{q+=1};prefix[i]=i64(q)}
 mark:[512]bool;for tr:=0;tr<r;tr+=1{for col:=0;col<=c-w;col+=1{for pr:=0;pr<h;pr+=1{equal:=true;for j:=0;j<w;j+=1{if text[tr*c+col+j]!=pat[pr*w+j]{equal=false}};mark[(tr*8+col)*8+pr]=equal}}}
 mr:[64]i64;mc:[64]i64;count:=0;for col:=0;col<=c-w;col+=1{q:=0;for tr:=0;tr<r;tr+=1{for q>0&&!mark[(tr*8+col)*8+q]{q=int(prefix[q-1])};if mark[(tr*8+col)*8+q]{q+=1};if q==h{mr[count]=i64(tr+1-h);mc[count]=i64(col);count+=1;q=int(prefix[h-1])}}}
 bytes:=8*(1+2*count);if output==nil||capacity<c.size_t(bytes) do return -2;put64(output,0,i64(count));for i:=0;i<count;i+=1{put64(output,8*(1+2*i),mr[i]);put64(output,8*(2+2*i),mc[i])};return i64(bytes)
}
