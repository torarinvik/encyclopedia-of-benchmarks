// Independent event-graph draft; compilation and output remain unverified.
const std = @import("std");

const Graph = struct {
    head: []i64, degree: []i64, first: []i64, to: []i64, next: []i64,
    nodes: usize = 0, edges: usize = 0,
    fn node(self: *Graph, first: bool) usize {
        const id=self.nodes; self.nodes+=1;
        self.head[id]=-1; self.degree[id]=0; self.first[id]=if (first) 1 else 0;
        return id;
    }
    fn edge(self: *Graph, from: usize, to: usize) void {
        const id=self.edges; self.edges+=1;
        self.to[id]=@intCast(to); self.next[id]=self.head[from]; self.head[from]=@intCast(id);
        self.degree[to]+=1;
    }
};
const Trees = struct {
    down: []usize, up: []usize, any: []usize,
    fn build(self: *Trees, graph: *Graph, node: usize, left: usize, right: usize) void {
        self.down[node]=graph.node(false); self.up[node]=graph.node(false); self.any[node]=graph.node(true);
        if (right-left==1) {
            graph.edge(self.down[node],left); graph.edge(left,self.up[node]); graph.edge(left,self.any[node]);
            return;
        }
        const mid=left+(right-left)/2;
        self.build(graph,2*node,left,mid); self.build(graph,2*node+1,mid,right);
        for (2*node..2*node+2) |child| {
            graph.edge(self.down[node],self.down[child]);
            graph.edge(self.up[child],self.up[node]);
            graph.edge(self.any[child],self.any[node]);
        }
    }
    fn connect(self: *const Trees, graph: *Graph, node: usize, left: usize, right: usize,
               ql: usize, qr: usize, kind: i64, target: usize) void {
        if (ql<=left and right<=qr) {
            if (kind==1) graph.edge(target,self.down[node])
            else if (kind==2) graph.edge(self.up[node],target)
            else graph.edge(self.any[node],target);
            return;
        }
        const mid=left+(right-left)/2;
        if (ql<mid) self.connect(graph,2*node,left,mid,ql,qr,kind,target);
        if (qr>mid) self.connect(graph,2*node+1,mid,right,ql,qr,kind,target);
    }
};

export fn range_constraint_topological_feasibility(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt==null or length<2) return -1;
    const input=input_opt.?[0..length];
    if (input[0]<1 or input[0]>4096 or input[1]<0 or input[1]>8192) return -1;
    const n: usize=@intCast(input[0]); const m: usize=@intCast(input[1]);
    if (length!=2+4*m) return -1;
    for (0..m) |i| {
        const kind=input[2+4*i]; const l=input[3+4*i]; const r=input[4+4*i]; const v=input[5+4*i];
        if (kind<1 or kind>3 or l<0 or l>=r or r>input[0] or v<0 or v>=input[0] or (l<=v and v<r)) return -1;
    }
    const node_cap=7*n+m+1; const edge_cap=9*n+32*m+1; const tree_cap=4*n;
    const allocator=std.heap.page_allocator;
    const memory=allocator.alloc(i64,4*node_cap+2*edge_cap) catch return -1;
    defer allocator.free(memory);
    const tree_memory=allocator.alloc(usize,3*tree_cap) catch return -1;
    defer allocator.free(tree_memory);
    var graph=Graph{
        .head=memory[0..node_cap], .degree=memory[node_cap..2*node_cap],
        .first=memory[2*node_cap..3*node_cap], .to=memory[4*node_cap..4*node_cap+edge_cap],
        .next=memory[4*node_cap+edge_cap..],
    };
    const queue=memory[3*node_cap..4*node_cap];
    var trees=Trees{.down=tree_memory[0..tree_cap], .up=tree_memory[tree_cap..2*tree_cap],
                    .any=tree_memory[2*tree_cap..]};
    for (0..n) |_| _=graph.node(false);
    trees.build(&graph,1,0,n);
    for (0..m) |i| {
        const kind=input[2+4*i]; const l: usize=@intCast(input[3+4*i]);
        const r: usize=@intCast(input[4+4*i]); const target: usize=@intCast(input[5+4*i]);
        if (kind==3) {
            const gate=graph.node(true);
            trees.connect(&graph,1,0,n,l,r,kind,gate); graph.edge(gate,target);
        } else trees.connect(&graph,1,0,n,l,r,kind,target);
    }
    var head: usize=0; var tail: usize=0; var emitted: usize=0;
    for (0..graph.nodes) |i| {
        if (graph.first[i]!=0) graph.degree[i]=1;
        if (graph.degree[i]==0) { queue[tail]=@intCast(i); tail+=1; }
    }
    while (head<tail) {
        const node: usize=@intCast(queue[head]); head+=1;
        if (node<n) emitted+=1;
        var edge=graph.head[node];
        while (edge>=0) {
            const e: usize=@intCast(edge); const target: usize=@intCast(graph.to[e]);
            if (graph.degree[target]>0) {
                graph.degree[target]-=1;
                if (graph.degree[target]==0) { queue[tail]=@intCast(target); tail+=1; }
            }
            edge=graph.next[e];
        }
    }
    return if (emitted==n) 1 else 0;
}
