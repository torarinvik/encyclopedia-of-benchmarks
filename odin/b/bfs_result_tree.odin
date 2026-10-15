package bfs_result_tree
import "core:c"
put_i64 :: proc "contextless"(output:[^]u8,word:usize,value:i64){bits:=transmute(u64)value;for b:=0;b<8;b+=1{output[word*8+b]=u8(bits>>u64(8*b))}}
@(export)
bfs_result_tree :: proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<3 do return -1
 nv,mv,sv:=input[0],input[1],input[2];if nv<1||nv>32||mv<0||mv>126||sv<0||sv>=nv||length!=usize(3+2*mv) do return -1
 n,m,start:=usize(nv),usize(mv),usize(sv);adj:[32*126]usize;degree:[32]usize;seen:[32]bool;parent:[32]i64;distance:[32]i64;queue:[32]usize;order:[32]usize
 for v:usize=0;v<32;v+=1{degree[v]=0;seen[v]=false;parent[v]=-1;distance[v]=-1}
 for e:usize=0;e<m;e+=1{a,b:=input[3+2*e],input[4+2*e];if a<0||a>=nv||b<0||b>=nv do return -1;ai:=usize(a);adj[ai*126+degree[ai]]=usize(b);degree[ai]+=1}
 head,tail,count:usize=0,0,0;seen[start]=true;distance[start]=0;queue[tail]=start;tail+=1
 for head<tail{v:=queue[head];head+=1;order[count]=v;count+=1;for j:usize=0;j<degree[v];j+=1{w:=adj[v*126+j];if !seen[w]{seen[w]=true;parent[w]=i64(v);distance[w]=distance[v]+1;queue[tail]=w;tail+=1}}}
 words:=4+6*count;if output==nil||capacity<words*8 do return -2;k:usize=0;put_i64(output,k,i64(count));k+=1;for i:usize=0;i<count;i+=1{put_i64(output,k,i64(order[i]));k+=1};put_i64(output,k,i64(count));k+=1;for i:usize=0;i<count;i+=1{put_i64(output,k,i64(order[i]));k+=1};put_i64(output,k,i64(count));k+=1;for i:usize=0;i<count;i+=1{v:=order[i];put_i64(output,k,i64(v));k+=1;put_i64(output,k,parent[v]);k+=1};put_i64(output,k,i64(count));k+=1;for i:usize=0;i<count;i+=1{v:=order[i];put_i64(output,k,i64(v));k+=1;put_i64(output,k,distance[v]);k+=1};return i64(words*8)
}
