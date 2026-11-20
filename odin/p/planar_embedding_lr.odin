package planar_embedding_lr
import "core:c"

Interval :: struct { low, high: int }
Conflict :: struct { left, right: Interval }
bool_int :: proc(value: bool) -> int { return if value { 1 } else { 0 } }
State :: struct {
    n,m: int,
    edge_of: [32][32]int, adj: [32][32]int, degree: [32]int,
    eu,ev,tail,head,low,low2,nest,reference,side,low_edge,bottom: [96]int,
    height,parent,out_count,rotation_count,left_ref,right_ref,roots: [32]int,
    out,rotation: [32][32]int,
    stack: [192]Conflict, stack_len,root_count: int,
}
empty_interval :: proc() -> Interval { return {-1,-1} }
empty_conflict :: proc() -> Conflict { return {empty_interval(),empty_interval()} }
is_empty :: proc(a: Interval) -> bool { return a.low<0 }
swap_intervals :: proc(p: ^Conflict) { t:=p.left; p.left=p.right; p.right=t }
update_parent :: proc(s: ^State, back, pe: int) {
    if pe<0{return}
    if s.low[back]<s.low[pe] { s.low2[pe]=min(s.low[pe],s.low2[back]);s.low[pe]=s.low[back] }
    else if s.low[back]>s.low[pe] { s.low2[pe]=min(s.low2[pe],s.low[back]) }
    else { s.low2[pe]=min(s.low2[pe],s.low2[back]) }
}
orient :: proc(s: ^State,v: int) {
    pe:=s.parent[v]
    for i:=0;i<s.degree[v];i+=1 {
        w:=s.adj[v][i];e:=s.edge_of[v][w]
        if s.tail[e]>=0{continue}
        s.tail[e]=v;s.head[e]=w;s.low[e]=s.height[v];s.low2[e]=s.height[v]
        if s.height[w]<0 {
            s.parent[w]=e;s.height[w]=s.height[v]+1;orient(s,w)
            s.nest[e]=2*s.low[e]+bool_int(s.low2[e]<s.height[v])
        } else {
            s.low[e]=s.height[w];s.low2[e]=s.height[v]
            s.nest[e]=2*s.low[e]+bool_int(s.low2[e]<s.height[v])
        }
        update_parent(s,e,pe)
    }
}
interval_conflicts :: proc(s: ^State,a: Interval,e: int)->bool{return a.high>=0&&s.low[a.high]>s.low[e]}
pair_lowest :: proc(s: ^State,p: Conflict)->int {
    a:=1000;b:=1000;if p.left.low>=0{a=s.low[p.left.low]};if p.right.low>=0{b=s.low[p.right.low]};return min(a,b)
}
add_constraints :: proc(s: ^State,ei,pe: int)->bool {
    p:=empty_conflict()
    for {
        if s.stack_len==0{return false}
        s.stack_len-=1;q:=s.stack[s.stack_len]
        if !is_empty(q.left){swap_intervals(&q)};if !is_empty(q.left){return false}
        if s.low[q.right.low]>s.low[pe] {
            if is_empty(p.right){p.right=q.right}else{s.reference[p.right.low]=q.right.high;p.right.low=q.right.low}
        }else{s.reference[q.right.low]=s.low_edge[pe]}
        if s.stack_len-1==s.bottom[ei]{break}
    }
    for s.stack_len>0&&(interval_conflicts(s,s.stack[s.stack_len-1].left,ei)||interval_conflicts(s,s.stack[s.stack_len-1].right,ei)) {
        s.stack_len-=1;q:=s.stack[s.stack_len]
        if interval_conflicts(s,q.right,ei){swap_intervals(&q)};if interval_conflicts(s,q.right,ei){return false}
        if p.right.low>=0{s.reference[p.right.low]=q.right.high};if q.right.low>=0{p.right.low=q.right.low}
        if is_empty(p.left){p.left=q.left}else{s.reference[p.left.low]=q.left.high;p.left.low=q.left.low}
    }
    if !is_empty(p.left)||!is_empty(p.right){s.stack[s.stack_len]=p;s.stack_len+=1};return true
}
remove_returns :: proc(s: ^State,e: int) {
    u:=s.tail[e]
    for s.stack_len>0&&pair_lowest(s,s.stack[s.stack_len-1])==s.height[u] {
        s.stack_len-=1;p:=s.stack[s.stack_len];if p.left.low>=0{s.side[p.left.low]=-1}
    }
    if s.stack_len>0 {
        s.stack_len-=1;p:=s.stack[s.stack_len]
        for p.left.high>=0&&s.head[p.left.high]==u{p.left.high=s.reference[p.left.high]}
        if p.left.high<0&&p.left.low>=0{s.reference[p.left.low]=p.right.low;s.side[p.left.low]=-1;p.left.low=-1}
        for p.right.high>=0&&s.head[p.right.high]==u{p.right.high=s.reference[p.right.high]}
        if p.right.high<0&&p.right.low>=0{s.reference[p.right.low]=p.left.low;s.side[p.right.low]=-1;p.right.low=-1}
        s.stack[s.stack_len]=p;s.stack_len+=1
    }
    if s.low[e]<s.height[u]&&s.stack_len>0 {p:=s.stack[s.stack_len-1];lh:=p.left.high;rh:=p.right.high;s.reference[e]=lh>=0&&(rh<0||s.low[lh]>s.low[rh])?lh:rh}
}
test_dfs :: proc(s: ^State,v: int)->bool {
    pe:=s.parent[v]
    for i:=0;i<s.out_count[v];i+=1 {
        e:=s.out[v][i];w:=s.head[e];s.bottom[e]=s.stack_len-1
        if s.parent[w]==e {if !test_dfs(s,w){return false}}
        else {
            s.low_edge[e]=e;p:=empty_conflict();p.right={e,e};s.stack[s.stack_len]=p;s.stack_len+=1
            if s.low[e]<s.height[v] {
                if i==0{if pe>=0{s.low_edge[pe]=e}}else if pe<0||!add_constraints(s,e,pe){return false}
            }
        }
    }
    if pe>=0{remove_returns(s,pe)};return true
}
resolve_side :: proc(s: ^State,e: int)->int {if s.reference[e]>=0{r:=s.reference[e];s.side[e]*=resolve_side(s,r);s.reference[e]=-1};return s.side[e]}
edge_before :: proc(s: ^State,a,b: int,depth: [96]int)->bool{return depth[a]<depth[b]||(depth[a]==depth[b]&&s.head[a]<s.head[b])}
insert_neighbor :: proc(s: ^State,v,w,reference: int,after: bool) {
    count:=s.rotation_count[v];pos:=0
    if count>0&&reference>=0{for pos<count&&s.rotation[v][pos]!=reference{pos+=1};if pos==count{pos=count}else if after{pos=(pos+1)%count}}
    for i:=count;i>pos;i-=1{s.rotation[v][i]=s.rotation[v][i-1]};s.rotation[v][pos]=w;s.rotation_count[v]=count+1
}
embed :: proc(s: ^State,v: int) {
    for i:=0;i<s.out_count[v];i+=1{e:=s.out[v][i];w:=s.head[e]
        if s.parent[w]==e{insert_neighbor(s,w,v,-1,false);s.left_ref[v]=w;s.right_ref[v]=w;embed(s,w)}
        else if s.side[e]==1{insert_neighbor(s,w,v,s.right_ref[w],true)}
        else{insert_neighbor(s,w,v,s.left_ref[w],false);s.left_ref[w]=v}
    }
}

@(export)
planar_embedding_lr :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t)->i64 {
    if input==nil||length<2||length>195{return -1};n64:=input[0];m64:=input[1]
    if n64<1||n64>32||m64<0||m64>96||length!=c.size_t(2+2*m64){return -1}
    s:State;s.n=int(n64);s.m=int(m64)
    for v:=0;v<s.n;v+=1{s.height[v]=-1;s.parent[v]=-1;s.left_ref[v]=-1;s.right_ref[v]=-1;for w:=0;w<s.n;w+=1{s.edge_of[v][w]=-1}}
    for e:=0;e<s.m;e+=1{s.tail[e]=-1;s.head[e]=-1;s.reference[e]=-1;s.side[e]=1;s.low_edge[e]=-1;s.bottom[e]=-1
        u64:=input[2+2*e];v64:=input[3+2*e];if u64<0||u64>=v64||v64>=n64{return -1};u:=int(u64);v:=int(v64);if s.edge_of[u][v]>=0{return -1};s.edge_of[u][v]=e;s.edge_of[v][u]=e;s.eu[e]=u;s.ev[e]=v}
    for v:=0;v<s.n;v+=1{for w:=0;w<s.n;w+=1{if s.edge_of[v][w]>=0{s.adj[v][s.degree[v]]=w;s.degree[v]+=1}}}
    for r:=0;r<s.n;r+=1{if s.height[r]<0{s.height[r]=0;s.roots[s.root_count]=r;s.root_count+=1;orient(&s,r)}}
    for e:=0;e<s.m;e+=1{v:=s.tail[e];s.out[v][s.out_count[v]]=e;s.out_count[v]+=1}
    for v:=0;v<s.n;v+=1{for i:=1;i<s.out_count[v];i+=1{e:=s.out[v][i];j:=i;for j>0&&edge_before(&s,e,s.out[v][j-1],s.nest){s.out[v][j]=s.out[v][j-1];j-=1};s.out[v][j]=e}}
    planar:=true;for i:=0;i<s.root_count;i+=1{if !test_dfs(&s,s.roots[i]){planar=false;break}}
    if output==nil{return -2};if !planar{if capacity<1{return -2};output[0]=0;return 1}
    depth:[96]int;for e:=0;e<s.m;e+=1{depth[e]=s.nest[e]*resolve_side(&s,e)}
    for v:=0;v<s.n;v+=1{for i:=1;i<s.out_count[v];i+=1{e:=s.out[v][i];j:=i;for j>0&&edge_before(&s,e,s.out[v][j-1],depth){s.out[v][j]=s.out[v][j-1];j-=1};s.out[v][j]=e}}
    for v:=0;v<s.n;v+=1{for i:=0;i<s.out_count[v];i+=1{s.rotation[v][s.rotation_count[v]]=s.head[s.out[v][i]];s.rotation_count[v]+=1}}
    for i:=0;i<s.root_count;i+=1{embed(&s,s.roots[i])}
    needed:=c.size_t(1+2*s.m);if capacity<needed{return -2};output[0]=1;at:=0
    for v:=0;v<s.n;v+=1{for i:=0;i<s.rotation_count[v];i+=1{output[at+1]=u8(s.rotation[v][i]);at+=1}}
    return i64(needed)
}
