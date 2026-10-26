module technology_mapping_minimum_area_tree_cover
const max_n=31
const max_output=256
const inf i64=2305843009213693951

fn put_i64(mut output &u8,offset int,value i64){bits:=u64(value);for b in 0..8{unsafe{output[offset+b]=u8((bits>>(8*b))&255)}}}

@[export:'technology_mapping_minimum_area_tree_cover']
pub fn technology_mapping_minimum_area_tree_cover(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{
    if input==nil||length<9||length>99||input[0]<1||input[0]>31{return -1};n:=int(input[0]);if length!=usize(6+3*n){return -1}
    mut costs:=[5]i64{};for p in 0..5{costs[p]=input[1+p];if costs[p]!=-1&&(costs[p]<1||costs[p]>1000000){return -1}}
    mut kind:=[max_n]int{};mut left:=[max_n]int{};mut right:=[max_n]int{};mut parents:=[max_n]int{}
    for i in 0..n{at:=6+3*i;k,l,r:=input[at],input[at+1],input[at+2];if k<0||k>2{return -1};kind[i]=int(k);left[i]=int(l);right[i]=int(r)
        if k==0{if l!=-1||r!=-1{return -1}}else if k==1{if l<=i64(i)||l>=i64(n)||r!=-1{return -1};parents[int(l)]++}else{if l<=i64(i)||l>=i64(n)||r<=i64(i)||r>=i64(n)||l==r{return -1};parents[int(l)]++;parents[int(r)]++}}
    if parents[0]!=0{return -1};for i in 1..n{if parents[i]!=1{return -1}}
    mut best:=[max_n]i64{};mut choice:=[max_n]int{};for i in 0..max_n{best[i]=inf;choice[i]=-1}
    for rev in 0..n{i:=n-1-rev;if kind[i]==0{best[i]=0;continue};l,r:=left[i],right[i];mut candidate:=i64(0)
        if kind[i]==1{if costs[0]>=0{candidate=costs[0]+best[l];if candidate<inf&&candidate<best[i]{best[i]=candidate;choice[i]=0}}}
        else{if costs[1]>=0{candidate=costs[1]+best[l]+best[r];if candidate<inf&&candidate<best[i]{best[i]=candidate;choice[i]=1}}
            if costs[2]>=0&&kind[l]==1{candidate=costs[2]+best[left[l]]+best[r];if candidate<inf&&candidate<best[i]{best[i]=candidate;choice[i]=2}}
            if costs[3]>=0&&kind[r]==1{candidate=costs[3]+best[l]+best[left[r]];if candidate<inf&&candidate<best[i]{best[i]=candidate;choice[i]=3}}
            if costs[4]>=0&&kind[l]==1&&kind[r]==1{candidate=costs[4]+best[left[l]]+best[left[r]];if candidate<inf&&candidate<best[i]{best[i]=candidate;choice[i]=4}}}}
    if best[0]==inf{return -1};mut mapping:=[max_n]i64{};for i in 0..n{mapping[i]=-3;if kind[i]==0{mapping[i]=-1}}
    mut stack:=[2*max_n]int{};mut top:=0;if kind[0]!=0{stack[top]=0;top++};for top>0{top--;node:=stack[top];p:=choice[node];l,r:=left[node],right[node];mapping[node]=i64(p)
        if p==0{stack[top]=l;top++}else if p==1{stack[top]=l;top++;stack[top]=r;top++}else if p==2{mapping[l]=-2;stack[top]=left[l];top++;stack[top]=r;top++}else if p==3{mapping[r]=-2;stack[top]=l;top++;stack[top]=left[r];top++}else{mapping[l]=-2;mapping[r]=-2;stack[top]=left[l];top++;stack[top]=left[r];top++}}
    bytes:=8*(n+1);if output==nil||capacity<usize(bytes){return -2};mut staged:=[max_output]u8{};put_i64(mut &staged[0],0,best[0]);for i in 0..n{put_i64(mut &staged[0],8*(i+1),mapping[i])};for i in 0..bytes{output[i]=staged[i]};return i64(bytes)
}}
