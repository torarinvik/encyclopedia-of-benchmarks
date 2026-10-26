package ppsz_k_sat_trace
import "core:c"

MAX_N :: 8
MAX_CLAUSES :: 12
MAX_INPUT :: 54
MAX_OUTPUT :: 72
put_i64 :: proc(out:[^]u8,at:int,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{out[at+i]=u8(bits&255);bits>>=8}}
fixed_mask :: proc(mask0:int,assigned:[^]int,n:int)->int{mask:=mask0;for i:=0;i<n;i+=1{if assigned[i]>=0{if assigned[i]==1{mask|=1<<i}else{mask&=~(1<<i)}}};return mask}
clause_true :: proc(clauses:[^]i64,index,mask:int)->bool{for j:=0;j<3;j+=1{lit:=clauses[3*index+j];bit:=(mask>>(int(abs(lit))-1))&1;if(lit>0&&bit==1||lit<0&&bit==0){return true}};return false}
selected_true :: proc(clauses:[^]i64,m,subset,mask:int)->bool{for i:=0;i<m;i+=1{if subset&(1<<i)!=0&&!clause_true(clauses,i,mask){return false}};return true}
popcount :: proc(value0:int)->int{value:=value0;count:=0;for value>0;value>>=1{count+=value&1};return count}
current_sat :: proc(n,m:int,clauses:[^]i64,assigned:[^]int)->bool{for mask:=0;mask<(1<<n);mask+=1{if selected_true(clauses,m,(1<<m)-1,fixed_mask(mask,assigned,n)){return true}};return false}
find_force :: proc(n,m:int,clauses:[^]i64,assigned:[^]int)->(bool,int,int){
    if !current_sat(n,m,clauses,assigned){return false,-1,-1};threshold:=0;for (1<<(threshold+1))<=n{threshold+=1};implied:[MAX_N]int;for i:=0;i<MAX_N;i+=1{implied[i]=-1}
    for subset:=1;subset<(1<<m);subset+=1{if popcount(subset)>threshold{continue};zero:[MAX_N]bool;one:[MAX_N]bool
        for mask:=0;mask<(1<<n);mask+=1{full:=fixed_mask(mask,assigned,n);if selected_true(clauses,m,subset,full){for x:=0;x<n;x+=1{if assigned[x]<0{if (full>>x)&1==1{one[x]=true}else{zero[x]=true}}}}}
        for x:=0;x<n;x+=1{if assigned[x]<0&&zero[x]!=one[x]&&implied[x]<0{if one[x]{implied[x]=1}else{implied[x]=0}}}}
    for x:=0;x<n;x+=1{if implied[x]>=0{return true,x,implied[x]}};return false,-1,-1
}

@(export)
ppsz_k_sat_trace :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64 {
    if input==nil||length<2||length>MAX_INPUT||input[0]<3||input[0]>MAX_N||input[1]<0||input[1]>MAX_CLAUSES{return -1};n,m:=int(input[0]),int(input[1]);if length!=c.size_t(2+3*m+2*n){return -1}
    clauses:[MAX_CLAUSES*3]i64;for i:=0;i<m;i+=1{seen:[MAX_N]bool;for j:=0;j<3;j+=1{lit:=input[2+3*i+j];if lit==0||lit < -i64(n)||lit>i64(n){return -1};x:=int(abs(lit))-1;if seen[x]{return -1};seen[x]=true;clauses[3*i+j]=lit}}
    start:=2+3*m;order:[MAX_N]int;beta:[MAX_N]int;assigned:[MAX_N]int;seen_var:[MAX_N]bool;for i:=0;i<MAX_N;i+=1{assigned[i]=-1}
    for i:=0;i<n;i+=1{x:=input[start+i];if x<0||x>=i64(n)||seen_var[int(x)]{return -1};order[i]=int(x);seen_var[int(x)]=true};for i:=0;i<n;i+=1{bit:=input[start+n+i];if bit!=0&&bit!=1{return -1};beta[i]=int(bit)}
    for step:=0;step<n;step+=1{for{ok,x,bit:=find_force(n,m,&clauses[0],&assigned[0]);if !ok{break};assigned[x]=bit};x:=order[step];if assigned[x]<0{assigned[x]=beta[x]}}
    mask:=0;for i:=0;i<n;i+=1{if assigned[i]==1{mask|=1<<i}};verdict:=i64(0);if selected_true(&clauses[0],m,(1<<m)-1,mask){verdict=1}
    bytes:=8*(n+1);if output==nil||capacity<c.size_t(bytes){return -2};staged:[MAX_OUTPUT]u8;put_i64(&staged[0],0,verdict);for i:=0;i<n;i+=1{put_i64(&staged[0],8*(i+1),i64(assigned[i]))};for i:=0;i<bytes;i+=1{output[i]=staged[i]};return i64(bytes)
}
