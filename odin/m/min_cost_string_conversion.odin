package min_cost_string_conversion
import "core:c"
MAX_CELLS :: 1089
put_i64_le :: proc "contextless" (output: [^]u8, pos: ^c.size_t, value: i64) { bits:=u64(value);for b:=c.size_t(0);b<8;b+=1{output[pos^]=u8((bits>>(8*b))&255);pos^+=1} }
@(export)
min_cost_string_conversion :: proc "contextless" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
 if input==nil||length<6||length>70 do return -1
 sn:=input[0];if sn<0||sn>32 do return -1;src:=c.size_t(sn);dp:=1+src;if dp>=length do return -1
 dn:=input[dp];if dn<0||dn>32 do return -1;dst:=c.size_t(dn);if length!=6+src+dst do return -1;tp:=dp+1;cp:=tp+dst
 for i:=c.size_t(0);i<src;i+=1{if input[1+i]<0||input[1+i]>127 do return -1};for j:=c.size_t(0);j<dst;j+=1{if input[tp+j]<0||input[tp+j]>127 do return -1};for k:=c.size_t(0);k<4;k+=1{if input[cp+k]< -1000||input[cp+k]>1000 do return -1}
 cc,rc,dc,ic:=input[cp],input[cp+1],input[cp+2],input[cp+3];rows,cols:=src+1,dst+1;cells:=rows*cols
 var costs:[MAX_CELLS]i64;var codes:[MAX_CELLS]i64;var ca:[MAX_CELLS]i64;var cb:[MAX_CELLS]i64
 for j:=c.size_t(1);j<cols;j+=1{x:=j;costs[x]=costs[x-1]+ic;codes[x]=4;cb[x]=input[tp+j-1]};for i:=c.size_t(1);i<rows;i+=1{x:=i*cols;costs[x]=costs[x-cols]+dc;codes[x]=3;ca[x]=input[i]}
 for i:=c.size_t(1);i<rows;i+=1{for j:=c.size_t(1);j<cols;j+=1{x:=i*cols+j;a,b:=input[i],input[tp+j-1];same:=a==b;best:=costs[x-cols-1]+rc;op:=i64(2);aa,bb:=a,b;if same{best=costs[x-cols-1]+cc;op=1;bb=0};deletion:=costs[x-cols]+dc;if deletion<best{best=deletion;op=3;aa=a;bb=0};insertion:=costs[x-1]+ic;if insertion<best{best=insertion;op=4;aa=0;bb=b};costs[x]=best;codes[x]=op;ca[x]=aa;cb[x]=bb}}
 needed:=c.size_t(32)+cells*32;if output==nil||capacity<needed do return -2;pos:=c.size_t(0);put_i64_le(output,&pos,i64(rows));put_i64_le(output,&pos,i64(cols));for x:=c.size_t(0);x<cells;x+=1{put_i64_le(output,&pos,costs[x])};put_i64_le(output,&pos,i64(rows));put_i64_le(output,&pos,i64(cols));for x:=c.size_t(0);x<cells;x+=1{put_i64_le(output,&pos,codes[x]);put_i64_le(output,&pos,ca[x]);put_i64_le(output,&pos,cb[x])};return i64(pos)
}
