package binary_tree_is_full
import "core:c"
MAX_N :: 1024
@(export)
binary_tree_is_full :: proc "c"(input:[^]i64,length:c.size_t)->i64{
    if input==nil||length<2||input[0]<1||input[0]>MAX_N do return -1
    n:=int(input[0]);root_value:=input[1];if root_value<0||root_value>=i64(n)||int(length)!=2+2*n do return -1
    left:[MAX_N]int;right:[MAX_N]int;parents:[MAX_N]int;stack:[MAX_N]int;seen:[MAX_N]bool;full:=true
    for i:=0;i<MAX_N;i+=1{parents[i]=0;seen[i]=false}
    for i:=0;i<n;i+=1{l:=input[2+2*i];r:=input[3+2*i];if l< -1||l>=i64(n)||r< -1||r>=i64(n)||l==i64(i)||r==i64(i) do return -1;left[i]=int(l);right[i]=int(r);if l>=0 do parents[int(l)]+=1;if r>=0 do parents[int(r)]+=1;if (l<0)!=(r<0) do full=false}
    root:=int(root_value);if parents[root]!=0 do return -1;for i:=0;i<n;i+=1{if i!=root&&parents[i]!=1 do return -1}
    top,visited:=1,0;stack[0]=root;for top>0{top-=1;node:=stack[top];if seen[node] do return -1;seen[node]=true;visited+=1;if left[node]>=0{stack[top]=left[node];top+=1};if right[node]>=0{stack[top]=right[node];top+=1}}
    if visited!=n do return -1
    if full do return 1
    return 0
}
