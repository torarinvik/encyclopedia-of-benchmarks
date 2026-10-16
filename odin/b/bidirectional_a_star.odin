package bidirectional_a_star
import "core:c"
MAX_CELLS :: 400
INF_COST :: 1_000_000
heuristic :: proc "contextless" (a,b,cols:int)->int {dy:=a/cols-b/cols;dx:=a%cols-b%cols;h:=0;for (h+1)*(h+1)<=dy*dy+dx*dx{h+=1};return h}
put_i64 :: proc "contextless" (out:[^]u8,slot:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[slot*8+i]=u8(bits>>u64(i*8))}}
@(export)
bidirectional_a_star :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<6||input[0]<1||input[0]>20||input[1]<1||input[1]>20 do return -1
 rows:=int(input[0]);cols:=int(input[1]);cells:=rows*cols
 sy:=input[2];sx:=input[3];gy:=input[4];gx:=input[5];if sy<0||sy>=i64(rows)||sx<0||sx>=i64(cols)||gy<0||gy>=i64(rows)||gx<0||gx>=i64(cols)||int(length)!=6+cells do return -1
 start:=int(sy)*cols+int(sx);goal:=int(gy)*cols+int(gx);blocked:[MAX_CELLS]bool
 for i:=0;i<cells;i+=1{v:=input[6+i];if v!=0&&v!=1 do return -1;blocked[i]=v==1};if blocked[start]||blocked[goal] do return -1
 g:[2][MAX_CELLS]int;parent:[2][MAX_CELLS]int;order:[2][MAX_CELLS]int;opened:[2][MAX_CELLS]bool;closed:[2][MAX_CELLS]bool;seq:[2]int
 for s:=0;s<2;s+=1{for i:=0;i<cells;i+=1{g[s][i]=INF_COST;parent[s][i]= -1}};g[0][start]=0;g[1][goal]=0;opened[0][start]=true;opened[1][goal]=true;seq[0]=1;seq[1]=1
 dr:=[4]int{-1,0,1,0};dc:=[4]int{0,-1,0,1};best:=INF_COST;meet:= -1
 for {min_g:=[2]int{INF_COST,INF_COST};for s:=0;s<2;s+=1{for v:=0;v<cells;v+=1{if opened[s][v]&&g[s][v]<min_g[s]{min_g[s]=g[s][v]}}};if best<INF_COST&&(min_g[0]==INF_COST||min_g[1]==INF_COST||min_g[0]+min_g[1]>=best) do break
  for s:=0;s<2;s+=1{target:=if s==0{goal}else{start};chosen:= -1;best_f:=INF_COST;for v:=0;v<cells;v+=1{if opened[s][v]{f:=g[s][v]+heuristic(v,target,cols);if chosen<0||f<best_f||(f==best_f&&order[s][v]<order[s][chosen]){chosen=v;best_f=f}}};if chosen<0 do continue;opened[s][chosen]=false;closed[s][chosen]=true;if g[1-s][chosen]<INF_COST&&g[s][chosen]+g[1-s][chosen]<best{best=g[s][chosen]+g[1-s][chosen];meet=chosen};y:=chosen/cols;x:=chosen%cols
   for d:=0;d<4;d+=1{ny:=y+dr[d];nx:=x+dc[d];if ny<0||ny>=rows||nx<0||nx>=cols do continue;v:=ny*cols+nx;if blocked[v]||closed[s][v] do continue;ng:=g[s][chosen]+1;if ng<g[s][v]{g[s][v]=ng;parent[s][v]=chosen;opened[s][v]=true;order[s][v]=seq[s];seq[s]+=1;if g[1-s][v]<INF_COST&&ng+g[1-s][v]<best{best=ng+g[1-s][v];meet=v}}}
  }
  any:=false;for s:=0;s<2;s+=1{for v:=0;v<cells;v+=1{any=any||opened[s][v]}};if !any do break
 }
 path:[MAX_CELLS]int;rev:[MAX_CELLS]int;count:=0;if meet<0{path[0]=start;count=1}else{n:=0;v:=meet;for v>=0{rev[n]=v;n+=1;v=parent[0][v]};for n>0{n-=1;path[count]=rev[n];count+=1};v=parent[1][meet];for v>=0{path[count]=v;count+=1;v=parent[1][v]}}
 bytes:=(1+2*count)*8;if output==nil||int(capacity)<bytes do return -2;put_i64(output,0,i64(count));for i:=0;i<count;i+=1{put_i64(output,1+2*i,i64(path[i]/cols));put_i64(output,2+2*i,i64(path[i]%cols))};return i64(bytes)
}
