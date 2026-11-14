// Uncompiled exact-length walk counting draft.
package fixed_length_walk_count
import "core:c"
@(export)
fixed_length_walk_count :: proc "c" (input: [^]i64, length: c.size_t) -> i64 {
    modulus :: i64(1000000007)
    if input==nil || length<4 || length>261 do return -1
    nv,k,source,target:=input[0],input[1],input[2],input[3]
    if nv<1 || nv>16 || k<0 || k>1000000000 || source<0 || source>=nv || target<0 || target>=nv || length!=c.size_t(4+nv*nv) do return -1
    n:=int(nv)
    matrix,next: [256]i64
    vector,temp: [16]i64
    for i:=0; i<n; i+=1 { for j:=0; j<n; j+=1 {
        value:=input[4+i*n+j]
        if value<0 || value>100 do return -1
        matrix[16*i+j]=value
    } }
    vector[int(source)]=1
    for k>0 {
        if k%2!=0 {
            for j:=0; j<n; j+=1 {
                temp[j]=0
                for i:=0; i<n; i+=1 { temp[j]=(temp[j]+vector[i]*matrix[16*i+j])%modulus }
            }
            for i:=0; i<n; i+=1 { vector[i]=temp[i] }
        }
        k/=2
        if k>0 {
            for i:=0; i<n; i+=1 { for j:=0; j<n; j+=1 {
                index:=16*i+j; next[index]=0
                for p:=0; p<n; p+=1 { next[index]=(next[index]+matrix[16*i+p]*matrix[16*p+j])%modulus }
            } }
            for i:=0; i<n; i+=1 { for j:=0; j<n; j+=1 { matrix[16*i+j]=next[16*i+j] } }
        }
    }
    return vector[int(target)]
}
