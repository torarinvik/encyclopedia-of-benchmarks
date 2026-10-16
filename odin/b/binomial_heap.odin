package binomial_heap
import "core:c"
M :: 128
R :: 9
E :: -1
Node :: struct { value:i64, child,sibling,degree:int }
Heap :: struct { nodes:[M]Node, roots:[R]int, used,size:int }
link :: proc(h:^Heap,a,b:int)->int{p,c:=a,b;if h.nodes[a].value>=h.nodes[b].value{p,c=b,a};h.nodes[c].sibling=h.nodes[p].child;h.nodes[p].child=c;h.nodes[p].degree+=1;return p}
add :: proc(h:^Heap,initial:int){r:=initial;d:=h.nodes[r].degree;for h.roots[d]!=E{r=link(h,r,h.roots[d]);h.roots[d]=E;d+=1};h.roots[d]=r}
insert :: proc(h:^Heap,v:i64){r:=h.used;h.used+=1;h.nodes[r]=Node{v,E,E,0};h.size+=1;add(h,r)}
minroot :: proc(h:^Heap)->int{best:=E;for r in h.roots{if r!=E&&(best==E||h.nodes[r].value<h.nodes[best].value){best=r}};return best}
extract :: proc(h:^Heap)->i64{b:=minroot(h);d:=h.nodes[b].degree;v:=h.nodes[b].value;h.roots[d]=E;c:=h.nodes[b].child;for c!=E{next:=h.nodes[c].sibling;h.nodes[c].sibling=E;add(h,c);c=next};h.size-=1;return v}
put :: proc(out:[^]u8,i:int,v:i64){bits:=u64(v);for b:=0;b<8;b+=1{out[i*8+b]=u8((bits>>(b*8))&255)}}
@(export) binomial_heap :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{if input==nil||length<1||input[0]<0||input[0]>M do return -1;n:=int(input[0]);if int(length)!=1+2*n do return -1;q,size:=0,0;for i:=0;i<n;i+=1{op:=input[1+2*i];v:=input[2+2*i];if op==0{if v< -2147483648||v>2147483647 do return -1;size+=1}else if op>=1&&op<=3{if v!=0||((op==1||op==2)&&size==0) do return -1;if op==2 do size-=1;q+=1}else do return -1};need:=q*8;if int(capacity)<need||(need>0&&output==nil) do return -2;h:Heap;for i:=0;i<R;i+=1{h.roots[i]=E};w:=0;for i:=0;i<n;i+=1{op:=input[1+2*i];v:=input[2+2*i];if op==0{insert(&h,v);continue};r:i64;if op==1{r=h.nodes[minroot(&h)].value}else if op==2{r=extract(&h)}else if h.size==0{r=1}else{r=0};put(output,w,r);w+=1};return i64(w)}
