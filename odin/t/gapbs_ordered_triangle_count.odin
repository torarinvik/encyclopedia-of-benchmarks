// Clean-room bounded port of GAPBS OrderedCount; see package LICENSE.txt.
package gapbs_ordered_triangle_count

import "core:c"

@(export)
gapbs_ordered_triangle_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 2 || length > 257 do return -1
    if input[0] < 1 || input[0] > 16 do return -1
    n := int(input[0])
    if int(length) != 1 + n*n do return -1
    var adjacency: [16][16]i64
    var neighbors: [16][16]int
    var degree: [16]int
    for u:=0;u<n;u+=1 {
        for v:=0;v<n;v+=1 {
            edge:=input[1+u*n+v]
            if (edge!=0 && edge!=1) || (u==v && edge!=0) do return -1
            adjacency[u][v]=edge
        }
    }
    for u:=0;u<n;u+=1 {
        for v:=u+1;v<n;v+=1 {if adjacency[u][v]!=adjacency[v][u] do return -1}
    }
    for u:=0;u<n;u+=1 {
        for v:=0;v<n;v+=1 {if adjacency[u][v]!=0 {neighbors[u][degree[u]]=v;degree[u]+=1}}
    }
    total:i64=0
    for u:=0;u<n;u+=1 {
        for vi:=0;vi<degree[u];vi+=1 {
            v:=neighbors[u][vi]
            if v>u do break
            edge_pos:=0
            for wi:=0;wi<degree[u];wi+=1 {
                w:=neighbors[u][wi]
                if w>v do break
                for edge_pos<degree[v] && neighbors[v][edge_pos]<w {edge_pos+=1}
                if edge_pos<degree[v] && neighbors[v][edge_pos]==w {total+=1}
            }
        }
    }
    return total
}
