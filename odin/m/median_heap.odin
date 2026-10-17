package median_heap

import "core:c"

MAX_OPERATIONS :: 256
MAX_INPUT_LENGTH :: 514
MAX_LIVE_VALUES :: 64
NIL_SENTINEL :: i64(-9223372036854775807 - 1)

store_i64_le :: proc "contextless" (output: [^]u8, offset: int, value: i64) { bits:=u64(value);for b:=0;b<8;b+=1{output[offset+b]=u8(bits>>u32(8*b))} }
push_max :: proc "contextless" (heap: [^]i32,count: ^int,value:i32){p:=count^;count^+=1;for p>0&&heap[(p-1)/2]<value{q:=(p-1)/2;heap[p]=heap[q];p=q};heap[p]=value}
pop_max :: proc "contextless" (heap: [^]i32,count: ^int)->i32{r:=heap[0];count^-=1;x:=heap[count^];if count^==0 do return r;p:=0;for 2*p+1<count^{c:=2*p+1;if c+1<count^&&heap[c+1]>heap[c]do c+=1;if heap[c]<=x do break;heap[p]=heap[c];p=c};heap[p]=x;return r}
push_min :: proc "contextless" (heap: [^]i32,count: ^int,value:i32){p:=count^;count^+=1;for p>0&&heap[(p-1)/2]>value{q:=(p-1)/2;heap[p]=heap[q];p=q};heap[p]=value}
pop_min :: proc "contextless" (heap: [^]i32,count: ^int)->i32{r:=heap[0];count^-=1;x:=heap[count^];if count^==0 do return r;p:=0;for 2*p+1<count^{c:=2*p+1;if c+1<count^&&heap[c+1]<heap[c]do c+=1;if heap[c]>=x do break;heap[p]=heap[c];p=c};heap[p]=x;return r}

@(export)
median_heap :: proc "c" (input: [^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<1||length>MAX_INPUT_LENGTH do return -1
	op_value:=input[0];if op_value<0||op_value>MAX_OPERATIONS||int(length)!=1+2*int(op_value)do return -1;count:=int(op_value)
	lower,upper:[MAX_LIVE_VALUES]i32;lc,uc:=0,0;results:[MAX_OPERATIONS]i64
	for i:=0;i<count;i+=1{op,arg:=input[1+2*i],input[2+2*i]
		if op==0{if arg< -2147483648||arg>2147483647||lc+uc>=MAX_LIVE_VALUES do return -1;x:=i32(arg)
			if lc==0 do push_max(&lower[0],&lc,x)else if x<lower[0]{push_max(&lower[0],&lc,x);if lc-uc>1 do push_min(&upper[0],&uc,pop_max(&lower[0],&lc))}else{push_min(&upper[0],&uc,x);if lc<uc do push_max(&lower[0],&lc,pop_min(&upper[0],&uc))};results[i]=NIL_SENTINEL
		}else if op>=1&&op<=4{if arg!=0 do return -1;if op==1{results[i]=if lc>0 do i64(lower[0])else NIL_SENTINEL}else if op==2{if lc==0 do results[i]=NIL_SENTINEL else{results[i]=i64(pop_max(&lower[0],&lc));if lc<uc do push_max(&lower[0],&lc,pop_min(&upper[0],&uc))}}else if op==3{results[i]=i64(lc+uc)}else{results[i]=if lc==0 do 1 else 0}}else do return -1
	}
	bytes:=count*8;if output==nil||capacity<c.size_t(bytes)do return -2;for i:=0;i<count;i+=1{store_i64_le(output,i*8,results[i])};return i64(bytes)
}
