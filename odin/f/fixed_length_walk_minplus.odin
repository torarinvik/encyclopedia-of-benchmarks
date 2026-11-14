// Uncompiled exact-length shortest-walk draft.
package fixed_length_walk_minplus
import "core:c"

@(export)
fixed_length_walk_minplus :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    inf :: i64(1000000000000000)
    if input==nil || length<4 || length>261 do return -100000002
    nv, k, source, target := input[0], input[1], input[2], input[3]
    if nv<1 || nv>16 || k<0 || k>1000000 || source<0 || source>=nv || target<0 || target>=nv || length!=c.size_t(4+nv*nv) do return -100000002
    n:=int(nv)
    matrix, next: [256]i64
    distance, temp: [16]i64
    for i:=0; i<n; i+=1 {
        distance[i]=inf
        for j:=0; j<n; j+=1 {
            weight:=input[4+i*n+j]
            if weight!=1000000 && (weight < -100 || weight>100) do return -100000002
            matrix[16*i+j]=weight
            if weight==1000000 { matrix[16*i+j]=inf }
        }
    }
    distance[int(source)]=0
    for k>0 {
        if k%2!=0 {
            for j:=0; j<n; j+=1 {
                temp[j]=inf
                for i:=0; i<n; i+=1 {
                    edge:=matrix[16*i+j]
                    if distance[i]!=inf && edge!=inf && distance[i]+edge<temp[j] { temp[j]=distance[i]+edge }
                }
            }
            for i:=0; i<n; i+=1 { distance[i]=temp[i] }
        }
        k/=2
        if k>0 {
            for i:=0; i<n; i+=1 { for j:=0; j<n; j+=1 {
                index:=16*i+j; next[index]=inf
                for p:=0; p<n; p+=1 {
                    a,b:=matrix[16*i+p],matrix[16*p+j]
                    if a!=inf && b!=inf && a+b<next[index] { next[index]=a+b }
                }
            } }
            for i:=0; i<n; i+=1 { for j:=0; j<n; j+=1 { matrix[16*i+j]=next[16*i+j] } }
        }
    }
    if distance[int(target)]==inf do return -100000001
    return distance[int(target)]
}
