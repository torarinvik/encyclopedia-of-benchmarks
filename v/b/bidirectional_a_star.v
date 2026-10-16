module bidirectional_a_star
const max_cells=400
const inf_cost=1000000
fn heuristic(a int,b int,cols int) int {dy:=a/cols-b/cols;dx:=a%cols-b%cols;mut h:=0;for (h+1)*(h+1)<=dy*dy+dx*dx{h++};return h}
fn put(out &u8,slot int,value i64){bits:=u64(value);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'bidirectional_a_star']
pub fn bidirectional_a_star(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<6{return -1};rows64:=unsafe{input[0]};cols64:=unsafe{input[1]};if rows64<1||rows64>20||cols64<1||cols64>20{return -1};rows:=int(rows64);cols:=int(cols64);cells:=rows*cols
 sy:=unsafe{input[2]};sx:=unsafe{input[3]};gy:=unsafe{input[4]};gx:=unsafe{input[5]};if sy<0||sy>=rows64||sx<0||sx>=cols64||gy<0||gy>=rows64||gx<0||gx>=cols64||length!=usize(6+cells){return -1};start:=int(sy)*cols+int(sx);goal:=int(gy)*cols+int(gx)
 mut blocked:=[max_cells]bool{};for i in 0..cells{v:=unsafe{input[6+i]};if v!=0&&v!=1{return -1};blocked[i]=v==1};if blocked[start]||blocked[goal]{return -1}
 mut g:=[2][max_cells]int{};mut parent:=[2][max_cells]int{};mut order:=[2][max_cells]int{};mut opened:=[2][max_cells]bool{};mut closed:=[2][max_cells]bool{};mut seq:=[2]int{}
 for s in 0..2{for i in 0..cells{g[s][i]=inf_cost;parent[s][i]= -1}};g[0][start]=0;g[1][goal]=0;opened[0][start]=true;opened[1][goal]=true;order[0][start]=0;order[1][goal]=0;seq[0]=1;seq[1]=1
 dr:=[4]int{-1,0,1,0};dc:=[4]int{0,-1,0,1};mut best:=inf_cost;mut meet:= -1
 for {
  mut min_g:=[2]int{inf_cost,inf_cost};for s in 0..2{for v in 0..cells{if opened[s][v]&&g[s][v]<min_g[s]{min_g[s]=g[s][v]}}};if best<inf_cost&&(min_g[0]==inf_cost||min_g[1]==inf_cost||min_g[0]+min_g[1]>=best){break}
  for s in 0..2{target:=if s==0{goal}else{start};mut chosen:= -1;mut best_f:=inf_cost;for v in 0..cells{if opened[s][v]{f:=g[s][v]+heuristic(v,target,cols);if chosen<0||f<best_f||(f==best_f&&order[s][v]<order[s][chosen]){chosen=v;best_f=f}}};if chosen<0{continue};opened[s][chosen]=false;closed[s][chosen]=true;if g[1-s][chosen]<inf_cost&&g[s][chosen]+g[1-s][chosen]<best{best=g[s][chosen]+g[1-s][chosen];meet=chosen};y:=chosen/cols;x:=chosen%cols
   for d in 0..4{ny:=y+dr[d];nx:=x+dc[d];if ny<0||ny>=rows||nx<0||nx>=cols{continue};v:=ny*cols+nx;if blocked[v]||closed[s][v]{continue};ng:=g[s][chosen]+1;if ng<g[s][v]{g[s][v]=ng;parent[s][v]=chosen;opened[s][v]=true;order[s][v]=seq[s];seq[s]++;if g[1-s][v]<inf_cost&&ng+g[1-s][v]<best{best=ng+g[1-s][v];meet=v}}}
  }
  mut any:=false;for s in 0..2{for v in 0..cells{any=any||opened[s][v]}};if !any{break}
 }
 mut path:=[max_cells]int{};mut rev:=[max_cells]int{};mut count:=0;if meet<0{path[0]=start;count=1}else{mut n:=0;mut v:=meet;for v>=0{rev[n]=v;n++;v=parent[0][v]};for n>0{n--;path[count]=rev[n];count++};v=parent[1][meet];for v>=0{path[count]=v;count++;v=parent[1][v]}}
 bytes:=(1+2*count)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(count));for i in 0..count{put(output,1+2*i,i64(path[i]/cols));put(output,2+2*i,i64(path[i]%cols))};return i64(bytes)
}
