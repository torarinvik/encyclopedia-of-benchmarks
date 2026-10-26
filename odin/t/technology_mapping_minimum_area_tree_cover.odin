package technology_mapping_minimum_area_tree_cover
import "core:c"

MAX_N :: 31
MAX_OUTPUT :: 256
INF : i64 = 2305843009213693951
put_i64 :: proc(out:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[offset+b]=u8(bits&255);bits>>=8}}

@(export)
technology_mapping_minimum_area_tree_cover :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<9||length>99||input[0]<1||input[0]>31{return -1};n:=int(input[0]);if length!=c.size_t(6+3*n){return -1}
    costs:[5]i64;for p:=0;p<5;p+=1{costs[p]=input[1+p];if costs[p]!=-1&&(costs[p]<1||costs[p]>1000000){return -1}}
    kind:[MAX_N]int;left,right,parents:[MAX_N]int
    for i:=0;i<n;i+=1{at:=6+3*i;k,l,r:=input[at],input[at+1],input[at+2];if k<0||k>2{return -1};kind[i]=int(k);left[i]=int(l);right[i]=int(r)
        if k==0{if l!=-1||r!=-1{return -1}}else if k==1{if l<=i64(i)||l>=i64(n)||r!=-1{return -1};parents[int(l)]+=1}else{if l<=i64(i)||l>=i64(n)||r<=i64(i)||r>=i64(n)||l==r{return -1};parents[int(l)]+=1;parents[int(r)]+=1}}
    if parents[0]!=0{return -1};for i:=1;i<n;i+=1{if parents[i]!=1{return -1}}
    best:[MAX_N]i64;choice:[MAX_N]int;for i:=0;i<MAX_N;i+=1{best[i]=INF;choice[i]=-1}
    for i:=n-1;i>=0;i-=1{if kind[i]==0{best[i]=0;continue};l,r:=left[i],right[i];var candidate:i64
        if kind[i]==1{if costs[0]>=0{candidate=costs[0]+best[l];if candidate<INF&&candidate<best[i]{best[i]=candidate;choice[i]=0}}}
        else{if costs[1]>=0{candidate=costs[1]+best[l]+best[r];if candidate<INF&&candidate<best[i]{best[i]=candidate;choice[i]=1}}
            if costs[2]>=0&&kind[l]==1{candidate=costs[2]+best[left[l]]+best[r];if candidate<INF&&candidate<best[i]{best[i]=candidate;choice[i]=2}}
            if costs[3]>=0&&kind[r]==1{candidate=costs[3]+best[l]+best[left[r]];if candidate<INF&&candidate<best[i]{best[i]=candidate;choice[i]=3}}
            if costs[4]>=0&&kind[l]==1&&kind[r]==1{candidate=costs[4]+best[left[l]]+best[left[r]];if candidate<INF&&candidate<best[i]{best[i]=candidate;choice[i]=4}}}}
    if best[0]==INF{return -1};mapping:[MAX_N]i64;for i:=0;i<n;i+=1{mapping[i]=-3;if kind[i]==0{mapping[i]=-1}}
    stack:[2*MAX_N]int;top:=0;if kind[0]!=0{stack[top]=0;top+=1};for top>0{top-=1;node:=stack[top];p:=choice[node];l,r:=left[node],right[node];mapping[node]=i64(p)
        if p==0{stack[top]=l;top+=1}else if p==1{stack[top]=l;top+=1;stack[top]=r;top+=1}else if p==2{mapping[l]=-2;stack[top]=left[l];top+=1;stack[top]=r;top+=1}else if p==3{mapping[r]=-2;stack[top]=l;top+=1;stack[top]=left[r];top+=1}else{mapping[l]=-2;mapping[r]=-2;stack[top]=left[l];top+=1;stack[top]=left[r];top+=1}}
    bytes:=8*(n+1);if output==nil||capacity<c.size_t(bytes){return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,best[0]);for i:=0;i<n;i+=1{put_i64(&staged[0],8*(i+1),mapping[i])};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
