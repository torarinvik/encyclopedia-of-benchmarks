module planar_embedding_lr

struct Interval { mut: low int; high int }
struct Conflict { mut: left Interval; right Interval }
struct State {
mut:
    n int; m int
    edge_of [32][32]int; adj [32][32]int; degree [32]int
    eu [96]int; ev [96]int; tail [96]int; head [96]int; low [96]int; low2 [96]int; nest [96]int
    reference [96]int; side [96]int; low_edge [96]int; bottom [96]int
    height [32]int; parent [32]int; out [32][32]int; out_count [32]int
    stack [192]Conflict; stack_len int
    rotation [32][32]int; rotation_count [32]int; left_ref [32]int; right_ref [32]int
    roots [32]int; root_count int
}
fn empty_interval() Interval { return Interval{low:-1,high:-1} }
fn empty_conflict() Conflict { return Conflict{left:empty_interval(),right:empty_interval()} }
fn is_empty(a Interval) bool { return a.low<0 }
fn bool_num(x bool) int { if x { return 1 }; return 0 }
fn swap_intervals(mut p Conflict) { t:=p.left;p.left=p.right;p.right=t }
fn update_parent(mut s State, back int, pe int) {
    if pe<0{return}
    if s.low[back]<s.low[pe]{s.low2[pe]=min(s.low[pe],s.low2[back]);s.low[pe]=s.low[back]}
    else if s.low[back]>s.low[pe]{s.low2[pe]=min(s.low2[pe],s.low[back])}
    else{s.low2[pe]=min(s.low2[pe],s.low2[back])}
}
fn orient(mut s State,v int) {
    pe:=s.parent[v]
    for i:=0;i<s.degree[v];i++{w:=s.adj[v][i];e:=s.edge_of[v][w];if s.tail[e]>=0{continue};s.tail[e]=v;s.head[e]=w;s.low[e]=s.height[v];s.low2[e]=s.height[v]
        if s.height[w]<0{s.parent[w]=e;s.height[w]=s.height[v]+1;orient(mut s,w);s.nest[e]=2*s.low[e]+bool_num(s.low2[e]<s.height[v])}
        else{s.low[e]=s.height[w];s.low2[e]=s.height[v];s.nest[e]=2*s.low[e]+bool_num(s.low2[e]<s.height[v])}
        update_parent(mut s,e,pe)
    }
}
fn interval_conflicts(s State,a Interval,e int) bool { return a.high>=0&&s.low[a.high]>s.low[e] }
fn pair_lowest(s State,p Conflict) int { a:=1000;b:=1000;if p.left.low>=0{a=s.low[p.left.low]};if p.right.low>=0{b=s.low[p.right.low]};return min(a,b) }
fn add_constraints(mut s State,ei int,pe int) bool {
    mut p:=empty_conflict()
    for{if s.stack_len==0{return false};s.stack_len--;mut q:=s.stack[s.stack_len];if !is_empty(q.left){swap_intervals(mut q)};if !is_empty(q.left){return false}
        if s.low[q.right.low]>s.low[pe]{if is_empty(p.right){p.right=q.right}else{s.reference[p.right.low]=q.right.high;p.right.low=q.right.low}}else{s.reference[q.right.low]=s.low_edge[pe]}
        if s.stack_len-1==s.bottom[ei]{break}
    }
    for s.stack_len>0&&(interval_conflicts(s,s.stack[s.stack_len-1].left,ei)||interval_conflicts(s,s.stack[s.stack_len-1].right,ei)){
        s.stack_len--;mut q:=s.stack[s.stack_len];if interval_conflicts(s,q.right,ei){swap_intervals(mut q)};if interval_conflicts(s,q.right,ei){return false}
        if p.right.low>=0{s.reference[p.right.low]=q.right.high};if q.right.low>=0{p.right.low=q.right.low}
        if is_empty(p.left){p.left=q.left}else{s.reference[p.left.low]=q.left.high;p.left.low=q.left.low}
    }
    if !is_empty(p.left)||!is_empty(p.right){s.stack[s.stack_len]=p;s.stack_len++};return true
}
fn remove_returns(mut s State,e int) {
    u:=s.tail[e]
    for s.stack_len>0&&pair_lowest(s,s.stack[s.stack_len-1])==s.height[u]{s.stack_len--;p:=s.stack[s.stack_len];if p.left.low>=0{s.side[p.left.low]=-1}}
    if s.stack_len>0{s.stack_len--;mut p:=s.stack[s.stack_len]
        for p.left.high>=0&&s.head[p.left.high]==u{p.left.high=s.reference[p.left.high]}
        if p.left.high<0&&p.left.low>=0{s.reference[p.left.low]=p.right.low;s.side[p.left.low]=-1;p.left.low=-1}
        for p.right.high>=0&&s.head[p.right.high]==u{p.right.high=s.reference[p.right.high]}
        if p.right.high<0&&p.right.low>=0{s.reference[p.right.low]=p.left.low;s.side[p.right.low]=-1;p.right.low=-1};s.stack[s.stack_len]=p;s.stack_len++
    }
    if s.low[e]<s.height[u]&&s.stack_len>0{p:=s.stack[s.stack_len-1];lh:=p.left.high;rh:=p.right.high;s.reference[e]=if lh>=0&&(rh<0||s.low[lh]>s.low[rh]){lh}else{rh}}
}
fn test_dfs(mut s State,v int) bool {
    pe:=s.parent[v]
    for i:=0;i<s.out_count[v];i++{e:=s.out[v][i];w:=s.head[e];s.bottom[e]=s.stack_len-1
        if s.parent[w]==e{if !test_dfs(mut s,w){return false}}
        else{s.low_edge[e]=e;mut p:=empty_conflict();p.right=Interval{low:e,high:e};s.stack[s.stack_len]=p;s.stack_len++
            if s.low[e]<s.height[v]{if i==0{if pe>=0{s.low_edge[pe]=e}}else if pe<0||!add_constraints(mut s,e,pe){return false}}
        }
    }
    if pe>=0{remove_returns(mut s,pe)};return true
}
fn resolve_side(mut s State,e int) int { if s.reference[e]>=0{r:=s.reference[e];s.side[e]*=resolve_side(mut s,r);s.reference[e]=-1};return s.side[e] }
fn edge_before(s State,a int,b int,depth [96]int) bool { return depth[a]<depth[b]||(depth[a]==depth[b]&&s.head[a]<s.head[b]) }
fn insert_neighbor(mut s State,v int,w int,reference int,after bool) {
    count:=s.rotation_count[v];mut pos:=0;if count>0&&reference>=0{for pos<count&&s.rotation[v][pos]!=reference{pos++};if pos==count{pos=count}else if after{pos=(pos+1)%count}}
    for i:=count;i>pos;i--{s.rotation[v][i]=s.rotation[v][i-1]};s.rotation[v][pos]=w;s.rotation_count[v]=count+1
}
fn embed(mut s State,v int) {
    for i:=0;i<s.out_count[v];i++{e:=s.out[v][i];w:=s.head[e]
        if s.parent[w]==e{insert_neighbor(mut s,w,v,-1,false);s.left_ref[v]=w;s.right_ref[v]=w;embed(mut s,w)}
        else if s.side[e]==1{insert_neighbor(mut s,w,v,s.right_ref[w],true)}
        else{insert_neighbor(mut s,w,v,s.left_ref[w],false);s.left_ref[w]=v}
    }
}

@[export: 'planar_embedding_lr']
pub fn planar_embedding_lr(input &i64,length usize,output &u8,capacity usize) i64 {
    unsafe {
        if isnil(input)||length<2||length>195{return -1};n64:=input[0];m64:=input[1]
        if n64<1||n64>32||m64<0||m64>96||length!=usize(2+2*m64){return -1}
        mut s:=State{n:int(n64),m:int(m64)}
        for v in 0..s.n{s.height[v]=-1;s.parent[v]=-1;s.left_ref[v]=-1;s.right_ref[v]=-1;for w in 0..s.n{s.edge_of[v][w]=-1}}
        for e in 0..s.m{s.tail[e]=-1;s.head[e]=-1;s.reference[e]=-1;s.side[e]=1;s.low_edge[e]=-1;s.bottom[e]=-1;u64:=input[2+2*e];v64:=input[3+2*e];if u64<0||u64>=v64||v64>=n64{return -1};u:=int(u64);v:=int(v64);if s.edge_of[u][v]>=0{return -1};s.edge_of[u][v]=e;s.edge_of[v][u]=e;s.eu[e]=u;s.ev[e]=v}
        for v in 0..s.n{for w in 0..s.n{if s.edge_of[v][w]>=0{s.adj[v][s.degree[v]]=w;s.degree[v]++}}}
        for r in 0..s.n{if s.height[r]<0{s.height[r]=0;s.roots[s.root_count]=r;s.root_count++;orient(mut s,r)}}
        for e in 0..s.m{v:=s.tail[e];s.out[v][s.out_count[v]]=e;s.out_count[v]++}
        for v in 0..s.n{for i:=1;i<s.out_count[v];i++{e:=s.out[v][i];mut j:=i;for j>0&&edge_before(s,e,s.out[v][j-1],s.nest){s.out[v][j]=s.out[v][j-1];j--};s.out[v][j]=e}}
        mut planar:=true;for i in 0..s.root_count{if !test_dfs(mut s,s.roots[i]){planar=false;break}}
        if isnil(output){return -2};if !planar{if capacity<1{return -2};output[0]=0;return 1}
        mut depth:=[96]int{};for e in 0..s.m{depth[e]=s.nest[e]*resolve_side(mut s,e)}
        for v in 0..s.n{for i:=1;i<s.out_count[v];i++{e:=s.out[v][i];mut j:=i;for j>0&&edge_before(s,e,s.out[v][j-1],depth){s.out[v][j]=s.out[v][j-1];j--};s.out[v][j]=e}}
        for v in 0..s.n{for i in 0..s.out_count[v]{s.rotation[v][s.rotation_count[v]]=s.head[s.out[v][i]];s.rotation_count[v]++}}
        for i in 0..s.root_count{embed(mut s,s.roots[i])}
        needed:=1+2*s.m;if capacity<needed{return -2};output[0]=1;mut at:=1
        for v in 0..s.n{for i in 0..s.rotation_count[v]{output[at]=u8(s.rotation[v][i]);at++}}
        return i64(needed)
    }
}
