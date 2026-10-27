@[export: 'kkt_mst_sampling_filter']
pub fn kkt_mst_sampling_filter(input &i64, length usize, output &u8, capacity usize) i64 {
    unsafe {
        if input==nil || length<6 || length>98 { return -1 }
        n64:=input[0];m64:=input[1]
        if n64<2 || n64>12 || m64<1 || m64>24 || length!=usize(2+4*m64) { return -1 }
        n:=int(n64);m:=int(m64)
        mut eu:=[]int{len:m,init:0};mut ev:=[]int{len:m,init:0};mut ew:=[]i64{len:m,init:0};mut sample:=[]int{len:m,init:0}
        for i in 0..m {
            eu[i]=int(input[2+4*i]);ev[i]=int(input[3+4*i]);ew[i]=input[4+4*i];sample[i]=int(input[5+4*i])
            if eu[i]<0 || eu[i]>=ev[i] || ev[i]>=n || ew[i]<1 || ew[i]>1024 || (sample[i]!=0&&sample[i]!=1) { return -1 }
            for j in 0..i { if (eu[i]==eu[j]&&ev[i]==ev[j]) || ew[i]==ew[j] { return -1 } }
        }
        if output==nil || capacity<m { return -2 }
        mut order:=[]int{len:m,init:0};for i in 0..m { order[i]=i }
        for i in 0..m { mut best:=i;for j in (i+1)..m { if ew[order[j]]<ew[order[best]] { best=j } };tmp:=order[i];order[i]=order[best];order[best]=tmp }
        mut parent:=[]int{len:n,init:0};for i in 0..n { parent[i]=i }
        mut in_forest:=[]bool{len:m,init:false};mut staged:=[]u8{len:m,init:0}
        for pos in 0..m {
            e:=order[pos];if sample[e]==0 { continue }
            mut a:=eu[e];mut b:=ev[e];for parent[a]!=a { a=parent[a] };for parent[b]!=b { b=parent[b] }
            if a!=b { parent[b]=a;in_forest[e]=true }
        }
        for e in 0..m {
            if in_forest[e] { staged[e]=1;continue }
            mut path_max:=[]i64{len:n,init:-1};mut queue:=[]int{len:n,init:0};mut seen:=[]bool{len:n,init:false}
            start:=eu[e];target:=ev[e];mut head:=0;mut tail:=1;queue[0]=start;seen[start]=true;path_max[start]=0
            for head<tail && !seen[target] {
                current:=queue[head];head++
                for k in 0..m {
                    if !in_forest[k] { continue }
                    mut next:=-1;if eu[k]==current { next=ev[k] } else if ev[k]==current { next=eu[k] }
                    if next>=0 && !seen[next] { seen[next]=true;path_max[next]=if path_max[current]>ew[k] {path_max[current]} else {ew[k]};queue[tail]=next;tail++ }
                }
            }
            if !seen[target] || ew[e]<path_max[target] { staged[e]=1 } else { staged[e]=0 }
        }
        for i in 0..m { output[i]=staged[i] }
        return i64(m)
    }
}
