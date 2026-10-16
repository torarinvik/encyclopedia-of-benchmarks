#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VARIABLES 40
#define MAX_CLAUSES 2047
#define MAX_LITERALS (2 * MAX_VARIABLES)
#define MAX_INPUT_LENGTH (2 + 2 * MAX_CLAUSES)

static void fill_order(const bool graph[MAX_LITERALS][MAX_LITERALS], size_t n, size_t v,
                       bool *seen, size_t *order, size_t *length) {
    seen[v] = true;
    for (size_t w = 0; w < n; ++w)
        if (graph[v][w] && !seen[w]) fill_order(graph, n, w, seen, order, length);
    order[(*length)++] = v;
}
static void assign_component(const bool graph[MAX_LITERALS][MAX_LITERALS], size_t n,
                              size_t v, int *component, int id) {
    component[v] = id;
    for (size_t w = 0; w < n; ++w)
        if (graph[v][w] && component[w] < 0) assign_component(graph, n, w, component, id);
}
int64_t two_sat(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_VARIABLES || input[1] < 0 || input[1] > MAX_CLAUSES) return -1;
    size_t variables=(size_t)input[0], clauses=(size_t)input[1], n=2*variables;
    if (length != 2+2*clauses) return -1;
    bool graph[MAX_LITERALS][MAX_LITERALS]={{false}}, transpose[MAX_LITERALS][MAX_LITERALS]={{false}};
    for (size_t i=0;i<clauses;i++) {
        int64_t a=input[2+2*i], b=input[3+2*i];
        if (!a || !b || a < -(int64_t)variables || a > (int64_t)variables || b < -(int64_t)variables || b > (int64_t)variables) return -1;
        size_t x=2*((size_t)(a<0?-a:a)-1)+(a<0), y=2*((size_t)(b<0?-b:b)-1)+(b<0);
        size_t edges[4]={x^1,y,y^1,x};
        for (size_t e=0;e<4;e+=2) { graph[edges[e]][edges[e+1]]=true; transpose[edges[e+1]][edges[e]]=true; }
    }
    bool seen[MAX_LITERALS]={false}; size_t order[MAX_LITERALS], olen=0;
    for(size_t v=0;v<n;v++) if(!seen[v]) fill_order(graph,n,v,seen,order,&olen);
    int component[MAX_LITERALS]; for(size_t v=0;v<n;v++) component[v]=-1;
    int id=0; while(olen){size_t v=order[--olen];if(component[v]<0)assign_component(transpose,n,v,component,id++);}
    bool satisfiable=true; for(size_t i=0;i<variables;i++) if(component[2*i]==component[2*i+1]) satisfiable=false;
    size_t outlen=satisfiable?variables+1:1;
    if(!output || capacity<outlen) return -2;
    output[0]=(uint8_t)satisfiable;
    if(satisfiable) for(size_t i=0;i<variables;i++) output[i+1]=(uint8_t)(component[2*i]>component[2*i+1]);
    return (int64_t)outlen;
}
