/* Independent compressed event-graph draft; uncompiled and unrun. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct {
    int *head, *degree, *first, *to, *next;
    int node_count, edge_count, node_cap, edge_cap, ok;
} rc_graph;

static int rc_node(rc_graph *g, int first) {
    if (g->node_count == g->node_cap) { g->ok = 0; return 0; }
    int v = g->node_count++;
    g->head[v] = -1; g->degree[v] = 0; g->first[v] = first;
    return v;
}

static void rc_edge(rc_graph *g, int from, int to) {
    if (!g->ok) return;
    if (g->edge_count == g->edge_cap) { g->ok = 0; return; }
    int e = g->edge_count++;
    g->to[e] = to; g->next[e] = g->head[from]; g->head[from] = e;
    ++g->degree[to];
}

typedef struct { rc_graph *g; int *down, *up, *any; } rc_trees;

static void rc_build(rc_trees *t, int index, int l, int r) {
    if (!t->g->ok) return;
    t->down[index] = rc_node(t->g, 0);
    t->up[index] = rc_node(t->g, 0);
    t->any[index] = rc_node(t->g, 1);
    if (!t->g->ok) return;
    if (r-l == 1) {
        rc_edge(t->g, t->down[index], l);
        rc_edge(t->g, l, t->up[index]);
        rc_edge(t->g, l, t->any[index]);
        return;
    }
    int mid = l+(r-l)/2;
    rc_build(t, 2*index, l, mid); rc_build(t, 2*index+1, mid, r);
    for (int child=2*index; child<=2*index+1; ++child) {
        rc_edge(t->g, t->down[index], t->down[child]);
        rc_edge(t->g, t->up[child], t->up[index]);
        rc_edge(t->g, t->any[child], t->any[index]);
    }
}

static void rc_connect(rc_trees *t, int index, int l, int r, int ql, int qr, int kind, int target) {
    if (!t->g->ok) return;
    if (ql<=l && r<=qr) {
        if (kind==1) rc_edge(t->g, target, t->down[index]);
        else if (kind==2) rc_edge(t->g, t->up[index], target);
        else rc_edge(t->g, t->any[index], target);
        return;
    }
    int mid=l+(r-l)/2;
    if (ql<mid) rc_connect(t,2*index,l,mid,ql,qr,kind,target);
    if (qr>mid) rc_connect(t,2*index+1,mid,r,ql,qr,kind,target);
}

int64_t range_constraint_topological_feasibility(const int64_t *input, size_t length) {
    if (!input || length<2 || input[0]<1 || input[0]>4096 || input[1]<0 || input[1]>8192) return -1;
    int n=(int)input[0], m=(int)input[1];
    if (length!=2+4*(size_t)m) return -1;
    for (int i=0; i<m; ++i) {
        int64_t k=input[2+4*i], l=input[3+4*i], r=input[4+4*i], v=input[5+4*i];
        if (k<1 || k>3 || l<0 || l>=r || r>n || v<0 || v>=n || (l<=v && v<r)) return -1;
    }
    rc_graph g={0};
    g.node_cap=7*n+m+1; g.edge_cap=9*n+32*m+1; g.ok=1;
    g.head=malloc((size_t)g.node_cap*sizeof(int));
    g.degree=malloc((size_t)g.node_cap*sizeof(int));
    g.first=malloc((size_t)g.node_cap*sizeof(int));
    g.to=malloc((size_t)g.edge_cap*sizeof(int));
    g.next=malloc((size_t)g.edge_cap*sizeof(int));
    int *queue=malloc((size_t)g.node_cap*sizeof(int));
    int *storage=calloc((size_t)(12*n),sizeof(int));
    int64_t result=-1;
    if (!g.head || !g.degree || !g.first || !g.to || !g.next || !queue || !storage) goto cleanup;
    rc_trees trees={&g,storage,storage+4*n,storage+8*n};
    for (int i=0; i<n; ++i) rc_node(&g,0);
    rc_build(&trees,1,0,n);
    for (int i=0; i<m && g.ok; ++i) {
        int kind=(int)input[2+4*i], l=(int)input[3+4*i], r=(int)input[4+4*i];
        int target=(int)input[5+4*i];
        if (kind==3) {
            int gate=rc_node(&g,1);
            rc_connect(&trees,1,0,n,l,r,kind,gate);
            rc_edge(&g,gate,target);
        } else rc_connect(&trees,1,0,n,l,r,kind,target);
    }
    if (!g.ok) goto cleanup;
    int head=0, tail=0, emitted=0;
    for (int i=0; i<g.node_count; ++i) {
        if (g.first[i]) g.degree[i]=1;
        if (g.degree[i]==0) queue[tail++]=i;
    }
    while (head<tail) {
        int u=queue[head++];
        if (u<n) ++emitted;
        for (int e=g.head[u]; e!=-1; e=g.next[e]) {
            int v=g.to[e];
            if (g.degree[v]>0 && --g.degree[v]==0) queue[tail++]=v;
        }
    }
    result=(emitted==n);
cleanup:
    free(storage); free(queue); free(g.next); free(g.to);
    free(g.first); free(g.degree); free(g.head);
    return result;
}
