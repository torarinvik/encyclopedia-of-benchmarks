package two_level_dynamic_maximal_matching_insertions
import "core:c"
put64 :: proc(o:[^]u8,at:int,x:i64){b:=u64(x);for i:=0;i<8;i+=1{o[at+i]=u8(b&255);b>>=8}}
owned :: proc(g:[^]bool,level:[^]i32,n,u:int,list:[^]i32)->int{z:=0;for v:=0;v<n;v+=1{if g[u*9+v]&&level[u]==0&&level[v]==0{list[z]=i32(v);z+=1}};return z}
repair :: proc(g:[^]bool,level:[^]i32,mate:[^]i32,n,u:int){if u<0||level[u]!=0||mate[u]>=0{return};for v:=0;v<n;v+=1{if g[u*9+v]&&level[v]==0&&mate[v]<0{mate[u]=i32(v);mate[v]=i32(u);return}}}
promote :: proc(g:[^]bool,level:[^]i32,mate:[^]i32,n,u:int,tape:[^]i32,r:int,used:^int)->bool{list:[9]i32;count:=owned(g,level,n,u,&list[0]);if count==0||used^>=r||tape[used^]>=i32(count){return false};y:=int(list[tape[used^]]);used^+=1;w,x:=int(mate[u]),int(mate[y]);if w>=0{mate[w]=-1;mate[u]=-1};if x>=0{mate[x]=-1;mate[y]=-1};level[u]=1;level[y]=1;mate[u]=i32(y);mate[y]=i32(u);if w>=0{repair(g,level,mate,n,w)};if x>=0&&x!=w{repair(g,level,mate,n,x)};return true}
@(export)
two_level_dynamic_maximal_matching_insertions :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3||length>55 do return -1;n0,q0:=input[0],input[1];if(n0!=4&&n0!=9)||q0<0||q0>24||q0>n0*(n0-1)/2 do return -1;n,q:=int(n0),int(q0);us:[24]int;vs:[24]int;seen:[81]bool;p:=2
 for e:=0;e<q;e+=1{u0,v0:=input[p],input[p+1];p+=2;if u0<0||v0<=u0||v0>=n0||seen[int(u0)*9+int(v0)] do return -1;seen[int(u0)*9+int(v0)]=true;us[e]=int(u0);vs[e]=int(v0)}
 if p>=int(length) do return -1;r0:=input[p];p+=1;if r0<0||r0>4||int(length)!=p+int(r0) do return -1;r:=int(r0);tape:[4]int32;for i:=0;i<r;i+=1{x:=input[p+i];if x<0||x>=n0 do return -1;tape[i]=i32(x)}
 graph:[81]bool;level:[9]int32;mate:[9]int32;for i:=0;i<n;i+=1{mate[i]=-1};used:=0;t:=if n==4{2}else{3}
 for e:=0;e<q;e+=1{u,v:=us[e],vs[e];graph[u*9+v]=true;graph[v*9+u]=true;if level[u]==1||level[v]==1{continue};if mate[u]<0&&mate[v]<0{mate[u]=i32(v);mate[v]=i32(u)};a,b:[9]int32;da:=owned(&graph[0],&level[0],n,u,&a[0]);db:=owned(&graph[0],&level[0],n,v,&b[0]);who:=if da>db||(da==db&&u<v){u}else{v};candidates:[9]int32;dc:=owned(&graph[0],&level[0],n,who,&candidates[0]);if dc>=t&&!promote(&graph[0],&level[0],&mate[0],n,who,&tape[0],r,&used){return -1}}
 if used!=r do return -1;bytes:=8*(1+2*n);if output==nil||capacity<c.size_t(bytes) do return -2;put64(output,0,i64(n));for i:=0;i<n;i+=1{put64(output,8+8*i,i64(level[i]))};for i:=0;i<n;i+=1{put64(output,8+8*n+8*i,i64(mate[i]))};return i64(bytes)
}
