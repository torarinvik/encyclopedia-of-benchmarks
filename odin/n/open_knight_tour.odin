package open_knight_tour
import "core:c"
dr:[8]int={1,-1,1,-1,2,2,-2,-2}
dc:[8]int={2,2,-2,-2,1,-1,1,-1}
search :: proc(b:^ [25]i32,n,r,c,step:int)->bool{if step==n*n{return true};for k:=0;k<8;k+=1{nr,nc:=r+dr[k],c+dc[k];if nr>=0&&nr<n&&nc>=0&&nc<n{at:=nr*n+nc;if b[at]==0{b[at]=i32(step+1);if search(b,n,nr,nc,step+1){return true};b[at]=0}}};return false}
put :: proc(outp:[^]u8,off:int,x:i32){bits:=transmute(u32)x;for k:=0;k<4;k+=1{outp[off+k]=u8(bits>>u32(8*k))}}
@(export)
open_knight_tour :: proc "c" (v:[^]i64,n:c.size_t,outp:[^]u8,cap:c.size_t)->i64{if v==nil||n!=1||v[0]<1||v[0]>5 do return -1;d:=int(v[0]);bytes:=d*d*4;if outp==nil||cap<c.size_t(bytes) do return -2;b:[25]i32;found:=false;for r:=0;r<d;r+=1{for col:=0;col<d;col+=1{b[r*d+col]=1;if search(&b,d,r,col,1){found=true;break};b[r*d+col]=0};if found{break}};for i:=0;i<d*d;i+=1{put(outp,i*4,b[i])};return i64(bytes)}
