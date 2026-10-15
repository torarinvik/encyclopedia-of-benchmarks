package k_nearest_neighbors_binary

import "core:c"

MAX_DIM :: 8
MAX_POINTS :: 128
put_i64 :: proc "contextless" (output:[^]u8,value:i64){bits:=u64(value);for i:=0;i<8;i+=1{output[i]=u8(bits>>(8*i))}}

@(export)
k_nearest_neighbors_binary :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<3 do return -1
	d64,n64,k64:=input[0],input[1],input[2]
	if d64<1||d64>MAX_DIM||n64<1||n64>MAX_POINTS||k64<1||k64>n64||k64%2==0||length!=c.size_t(3+d64+n64*(d64+1)) do return -1
	d,n,k:=int(d64),int(n64),int(k64)
	for axis:=0;axis<d;axis+=1{if input[3+axis]< -1000||input[3+axis]>1000 do return -1}
	var distances:[MAX_POINTS]i64;var labels:[MAX_POINTS]i64
	for point:=0;point<n;point+=1{base:=3+d+point*(d+1);sum:i64=0
		for axis:=0;axis<d;axis+=1{x:=input[base+axis];if x< -1000||x>1000 do return -1;delta:=x-input[3+axis];sum+=delta*delta}
		label:=input[base+d];if label!=0&&label!=1 do return -1
		for prev:=0;prev<point;prev+=1{if distances[prev]==sum do return -1};distances[point]=sum;labels[point]=label
	}
	for i:=1;i<n;i+=1{distance,label:=distances[i],labels[i];j:=i;for j>0&&distances[j-1]>distance{distances[j]=distances[j-1];labels[j]=labels[j-1];j-=1};distances[j]=distance;labels[j]=label}
	ones:i64=0;for i:=0;i<k;i+=1{ones+=labels[i]};prediction:i64=0;if ones>i64(k/2){prediction=1}
	if output==nil||capacity<8 do return -2
	put_i64(output,prediction);return 8
}
