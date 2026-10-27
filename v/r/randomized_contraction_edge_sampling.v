fn put32(output &u8, pos usize, value i32) {
    unsafe {
        bits:=u32(value)
        for j in 0..4 { output[pos+j]=u8((bits>>(8*j))&255) }
    }
}

@[export: 'randomized_contraction_edge_sampling']
pub fn randomized_contraction_edge_sampling(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input==nil || length<5 || length>74 { return -1 }
        n64:=input[0];m64:=input[1]
        if n64<2 || n64>16 || m64<n64-1 || m64>24 || length!=usize(2+3*m64) { return -1 }
        n:=int(n64);m:=int(m64)
        mut eu:=[]int{len:m,init:0};mut ev:=[]int{len:m,init:0};mut bits:=[]int{len:m,init:0}
        for i in 0..m {
            eu[i]=int(input[2+3*i]);ev[i]=int(input[3+3*i]);bits[i]=int(input[4+3*i])
            if eu[i]<0 || eu[i]>=ev[i] || ev[i]>=n || (bits[i]!=0&&bits[i]!=1) { return -1 }
            for j in 0..i { if eu[i]==eu[j] && ev[i]==ev[j] { return -1 } }
        }
        mut seen:=[]bool{len:n,init:false};mut queue:=[]int{len:n,init:0};mut head:=0;mut tail:=1;queue[0]=0;seen[0]=true
        for head<tail {
            current:=queue[head];head++
            for e in 0..m {
                mut next:=-1;if eu[e]==current {next=ev[e]} else if ev[e]==current {next=eu[e]}
                if next>=0 && !seen[next] {seen[next]=true;queue[tail]=next;tail++}
            }
        }
        if tail!=n { return -1 }
        mut parent:=[]int{len:n,init:0};for i in 0..n {parent[i]=i}
        for e in 0..m {
            if bits[e]!=0 {mut a:=eu[e];mut b:=ev[e];for parent[a]!=a {a=parent[a]};for parent[b]!=b {b=parent[b]};if a!=b {parent[b]=a}}
        }
        mut minimum:=[]int{len:n,init:n}
        for vertex in 0..n {mut root:=vertex;for parent[root]!=root {root=parent[root]};if vertex<minimum[root] {minimum[root]=vertex}}
        bytes:=4*n
        if output==nil || capacity<bytes { return -2 }
        mut staged:=[]u8{len:bytes,init:0}
        for vertex in 0..n {mut root:=vertex;for parent[root]!=root {root=parent[root]};put32(&staged[0],4*vertex,i32(minimum[root]))}
        for i in 0..bytes {output[i]=staged[i]}
        return i64(bytes)
    }
}
