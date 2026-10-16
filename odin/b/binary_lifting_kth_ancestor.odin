package binary_lifting_kth_ancestor
import "core:c"
MAX_NODES :: 256
MAX_QUERIES :: 1024
LEVELS :: 9
put_i64 :: proc "contextless" (out:[^]u8,slot:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[slot*8+i]=u8(bits>>u64(i*8))}}
@(export)
binary_lifting_kth_ancestor :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<4||input[0]<1||input[0]>MAX_NODES do return -1
 n:=int(input[0]);if input[1]<0||input[1]>=i64(n)||input[2]!=i64(n-1)||input[3]<0||input[3]>MAX_QUERIES do return -1
 m:=int(input[2]);q:=int(input[3]);qo:=4+2*m;if int(length)!=qo+2*q do return -1;root:=int(input[1])
 adj:[MAX_NODES][MAX_NODES]bool
 for e:=0;e<m;e+=1{a:=input[4+2*e];b:=input[5+2*e];if a<0||b<0||a>=i64(n)||b>=i64(n)||a==b do return -1;adj[int(a)][int(b)]=true;adj[int(b)][int(a)]=true}
 for i:=0;i<q;i+=1{v:=input[qo+2*i];k:=input[qo+2*i+1];if v<0||v>=i64(n)||k<0 do return -1}
 up:[LEVELS][MAX_NODES]int;parent:[MAX_NODES]int;stack:[MAX_NODES]int;for i:=0;i<n;i+=1{parent[i]= -1};parent[root]=root;up[0][root]=root;top:=0;reached:=0;stack[top]=root;top+=1
 for top>0{top-=1;u:=stack[top];reached+=1;for v:=0;v<n;v+=1{if adj[u][v]{if v==parent[u] do continue;if parent[v]!= -1 do return -1;parent[v]=u;up[0][v]=u;stack[top]=v;top+=1}}};if reached!=n do return -1
 for level:=1;level<LEVELS;level+=1{for v:=0;v<n;v+=1{up[level][v]=up[level-1][up[level-1][v]]}}
 bytes:=(1+q)*8;if output==nil||int(capacity)<bytes do return -2;put_i64(output,0,i64(q))
 for i:=0;i<q;i+=1{v:=int(input[qo+2*i]);k:=u64(input[qo+2*i+1]);if k>=u64(n){v=root}else{for bit:=0;bit<LEVELS;bit+=1{if k&(u64(1)<<u64(bit))!=0{v=up[bit][v]}}};put_i64(output,1+i,i64(v))};return i64(bytes)
}
