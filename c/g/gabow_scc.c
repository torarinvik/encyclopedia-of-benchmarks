/* Clean-room iterative Gabow path-based strongly connected components. */
#include <stddef.h>
#include <stdint.h>

int64_t gabow_scc(const int64_t *input, size_t length,
                  uint8_t *output, size_t output_capacity) {
    enum { MAX_N = 40, MAX_M = 2047, MAX_INPUT = 4096, MAX_OUTPUT = 81 };
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2*m) return -1;
    uint64_t adjacency[MAX_N] = {0};
    size_t neighbors[MAX_N * MAX_N] = {0}, degree[MAX_N] = {0};
    for (size_t e=0; e<m; ++e) {
        const int64_t source=input[2+2*e], target=input[3+2*e];
        if (source<0 || target<0 || source>=(int64_t)n || target>=(int64_t)n) return -1;
        const size_t u=(size_t)source, v=(size_t)target;
        const uint64_t bit=UINT64_C(1) << v;
        if ((adjacency[u] & bit)==0) {
            adjacency[u] |= bit;
            neighbors[u*MAX_N+degree[u]++]=v;
        }
    }
    int64_t preorder[MAX_N], component[MAX_N];
    size_t vertices[MAX_N], boundaries[MAX_N], dfs[MAX_N], next_neighbor[MAX_N];
    for (size_t v=0; v<n; ++v) { preorder[v]=-1; component[v]=-1; }
    size_t vertex_count=0, boundary_count=0, depth=0, clock=0, component_count=0;
    for (size_t root=0; root<n; ++root) {
        if (preorder[root]>=0) continue;
        preorder[root]=(int64_t)clock++;
        vertices[vertex_count++]=root;
        boundaries[boundary_count++]=root;
        dfs[depth]=root; next_neighbor[depth]=0; ++depth;
        while (depth>0) {
            const size_t frame=depth-1, v=dfs[frame];
            if (next_neighbor[frame] < degree[v]) {
                const size_t w=neighbors[v*MAX_N+next_neighbor[frame]++];
                if (preorder[w]<0) {
                    preorder[w]=(int64_t)clock++;
                    vertices[vertex_count++]=w;
                    boundaries[boundary_count++]=w;
                    dfs[depth]=w; next_neighbor[depth]=0; ++depth;
                } else if (component[w]<0) {
                    while (boundary_count>0 &&
                           preorder[boundaries[boundary_count-1]]>preorder[w]) --boundary_count;
                }
            } else {
                --depth;
                if (boundary_count>0 && boundaries[boundary_count-1]==v) {
                    --boundary_count;
                    for (;;) {
                        const size_t member=vertices[--vertex_count];
                        component[member]=(int64_t)component_count;
                        if (member==v) break;
                    }
                    ++component_count;
                }
            }
        }
    }
    uint8_t staged[MAX_OUTPUT];
    size_t position=1;
    staged[0]=(uint8_t)component_count;
    for (size_t first=0; first<n; ++first) {
        const int64_t id=component[first];
        int seen=0;
        for (size_t earlier=0; earlier<first; ++earlier) if (component[earlier]==id) seen=1;
        if (seen) continue;
        size_t size=0;
        for (size_t v=first; v<n; ++v) if (component[v]==id) ++size;
        staged[position++]=(uint8_t)size;
        for (size_t v=first; v<n; ++v) if (component[v]==id) staged[position++]=(uint8_t)v;
    }
    if (output==NULL || output_capacity<position) return -2;
    for (size_t q=0; q<position; ++q) output[q]=staged[q];
    return (int64_t)position;
}
