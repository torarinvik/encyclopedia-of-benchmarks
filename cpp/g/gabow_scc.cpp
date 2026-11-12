/* Clean-room iterative Gabow path-based strongly connected components. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gabow_scc(const std::int64_t* input, std::size_t length,
                                  std::uint8_t* output, std::size_t output_capacity) noexcept {
    constexpr std::size_t MAX_N=40, MAX_M=2047, MAX_INPUT=4096, MAX_OUTPUT=81;
    if (!input || length<2 || length>MAX_INPUT) return -1;
    if (input[0]<0 || input[0]>static_cast<std::int64_t>(MAX_N) ||
        input[1]<0 || input[1]>static_cast<std::int64_t>(MAX_M)) return -1;
    const auto n=static_cast<std::size_t>(input[0]), m=static_cast<std::size_t>(input[1]);
    if (length!=2+2*m) return -1;
    std::uint64_t adjacency[MAX_N]{};
    std::size_t neighbors[MAX_N*MAX_N]{}, degree[MAX_N]{};
    for (std::size_t e=0; e<m; ++e) {
        const auto source=input[2+2*e], target=input[3+2*e];
        if (source<0 || target<0 || source>=static_cast<std::int64_t>(n) ||
            target>=static_cast<std::int64_t>(n)) return -1;
        const auto u=static_cast<std::size_t>(source), v=static_cast<std::size_t>(target);
        const auto bit=UINT64_C(1)<<v;
        if ((adjacency[u]&bit)==0) { adjacency[u]|=bit; neighbors[u*MAX_N+degree[u]++]=v; }
    }
    std::int64_t preorder[MAX_N], component[MAX_N];
    std::size_t vertices[MAX_N], boundaries[MAX_N], dfs[MAX_N], next_neighbor[MAX_N];
    for (std::size_t v=0; v<n; ++v) { preorder[v]=-1; component[v]=-1; }
    std::size_t vertex_count=0, boundary_count=0, depth=0, clock=0, component_count=0;
    for (std::size_t root=0; root<n; ++root) {
        if (preorder[root]>=0) continue;
        preorder[root]=static_cast<std::int64_t>(clock++);
        vertices[vertex_count++]=root; boundaries[boundary_count++]=root;
        dfs[depth]=root; next_neighbor[depth]=0; ++depth;
        while (depth>0) {
            const auto frame=depth-1, v=dfs[frame];
            if (next_neighbor[frame]<degree[v]) {
                const auto w=neighbors[v*MAX_N+next_neighbor[frame]++];
                if (preorder[w]<0) {
                    preorder[w]=static_cast<std::int64_t>(clock++);
                    vertices[vertex_count++]=w; boundaries[boundary_count++]=w;
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
                        const auto member=vertices[--vertex_count];
                        component[member]=static_cast<std::int64_t>(component_count);
                        if (member==v) break;
                    }
                    ++component_count;
                }
            }
        }
    }
    std::uint8_t staged[MAX_OUTPUT]{}; std::size_t position=1;
    staged[0]=static_cast<std::uint8_t>(component_count);
    for (std::size_t first=0; first<n; ++first) {
        const auto id=component[first]; bool seen=false;
        for (std::size_t earlier=0; earlier<first; ++earlier) if (component[earlier]==id) seen=true;
        if (seen) continue;
        std::size_t size=0;
        for (std::size_t v=first; v<n; ++v) if (component[v]==id) ++size;
        staged[position++]=static_cast<std::uint8_t>(size);
        for (std::size_t v=first; v<n; ++v) if (component[v]==id) staged[position++]=static_cast<std::uint8_t>(v);
    }
    if (!output || output_capacity<position) return -2;
    for (std::size_t q=0; q<position; ++q) output[q]=staged[q];
    return static_cast<std::int64_t>(position);
}
