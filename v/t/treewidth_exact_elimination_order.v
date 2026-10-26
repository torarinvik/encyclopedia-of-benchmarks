module treewidth_exact_elimination_order
const max_n=8
const max_edges=28
const max_input=58
const max_output=72

fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for byte in 0..8{unsafe{output[offset+byte]=u8((bits>>(8*byte))&255)}}}

@[export:'treewidth_exact_elimination_order']
pub fn treewidth_exact_elimination_order(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
    if input==nil||length<2||length>max_input||input[0]<1||input[0]>max_n||input[1]<0||input[1]>max_edges{return -1};n,m:=int(input[0]),int(input[1]);if m>n*(n-1)/2||length!=usize(2+2*m){return -1}
    mut base:=[max_n][max_n]bool{};for e in 0..m{a0,b0:=input[2+2*e],input[3+2*e];if a0<0||b0<0||a0>=i64(n)||b0>=i64(n)||a0>=b0{return -1};a,b:=int(a0),int(b0);if base[a][b]{return -1};base[a][b]=true;base[b][a]=true}
    mut perm:=[max_n]int{};mut best_order:=[max_n]int{};for i in 0..n{perm[i]=i};mut best_width:=max_n+1
    for{mut adjacent:=base;mut active:=[max_n]bool{};for i in 0..n{active[i]=true};mut width:=0
        for step in 0..n{vertex:=perm[step];mut neighbors:=[max_n]int{};mut count:=0;for other in 0..n{if active[other]&&adjacent[vertex][other]{neighbors[count]=other;count++}};if count>width{width=count};for i in 0..count{for j in i+1..count{a,b:=neighbors[i],neighbors[j];adjacent[a][b]=true;adjacent[b][a]=true}};active[vertex]=false}
        if width<best_width{best_width=width;for i in 0..n{best_order[i]=perm[i]}};mut pivot:=n-2;for pivot>=0&&perm[pivot]>=perm[pivot+1]{pivot--};if pivot<0{break};mut successor:=n-1;for perm[successor]<=perm[pivot]{successor--};temp:=perm[pivot];perm[pivot]=perm[successor];perm[successor]=temp;mut left:=pivot+1;mut right:=n-1;for left<right{temp=perm[left];perm[left]=perm[right];perm[right]=temp;left++;right--}
    }
    bytes:=8*(n+1);if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};put_i64(mut &staged[0],0,i64(best_width));for i in 0..n{put_i64(mut &staged[0],8*(i+1),i64(best_order[i]))};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
}}
