// Clean-room bounded Brandes profile; see package LICENSE.txt.
package gapbs_betweenness_centrality

import "core:c"

@(export)
gapbs_betweenness_centrality :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    if input == nil || length < 12 || length > 74 do return -1
    if input[0] < 3 || input[0] > 8 || input[1] < 1 || input[1] > input[0] do return -1
    n, k := int(input[0]), int(input[1])
    if int(length) != 2+k+n*n do return -1
    sources: [8]int
    for i:=0;i<k;i+=1 {
        raw:=input[2+i]
        if raw<0 || raw>=i64(n) do return -1
        sources[i]=int(raw)
        for j:=0;j<i;j+=1 {if sources[j]==sources[i] do return -1}
    }
    adjacency: [8][8]int
    for u:=0;u<n;u+=1 {
        for v:=0;v<n;v+=1 {
            edge:=input[2+k+u*n+v]
            if (edge!=0 && edge!=1) || (u==v && edge!=0) do return -1
            adjacency[u][v]=int(edge)
        }
    }
    for u:=0;u<n;u+=1 {for v:=u+1;v<n;v+=1 {if adjacency[u][v]!=adjacency[v][u] do return -1}}

    scores: [8]f32
    for si:=0;si<k;si+=1 {
        depth: [8]int
        queue: [8]int
        paths: [8]f64
        delta: [8]f32
        for v:=0;v<n;v+=1 {depth[v]=-1}
        source:=sources[si]
        depth[source]=0;paths[source]=1.0
        head,tail:=0,1
        queue[0]=source
        for head<tail {
            u:=queue[head];head+=1
            for v:=0;v<n;v+=1 {
                if adjacency[u][v]!=0 {
                    if depth[v]==-1 {depth[v]=depth[u]+1;queue[tail]=v;tail+=1}
                    if depth[v]==depth[u]+1 {paths[v]+=paths[u]}
                }
            }
        }
        max_depth:=0
        for v:=0;v<n;v+=1 {if depth[v]>max_depth {max_depth=depth[v]}}
        for d:=max_depth;d>=0;d-=1 {
            for u:=0;u<n;u+=1 {
                if depth[u]==d {
                    delta_u:f32=0
                    for v:=0;v<n;v+=1 {
                        if adjacency[u][v]!=0 && depth[v]==d+1 {
                            one_plus:=f32(1.0)+delta[v]
                            contribution:=(paths[u]/paths[v])*f64(one_plus)
                            delta_u=f32(f64(delta_u)+contribution)
                        }
                    }
                    delta[u]=delta_u
                    scores[u]=f32(f64(scores[u])+f64(delta_u))
                }
            }
        }
    }
    biggest:f32=0
    for v:=0;v<n;v+=1 {if scores[v]>biggest {biggest=scores[v]}}
    if !(biggest>0) do return -1
    checksum:i64=0
    for v:=0;v<n;v+=1 {
        normalized:=scores[v]/biggest
        qscore:=i64(f64(normalized)*1000.0+0.5)
        checksum+=i64(v+1)*qscore
    }
    return checksum
}
