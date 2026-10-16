package tournament_sort
import "core:c"
MAX_VALUES::512
choose::proc "contextless"(values:[^]i64,tree:[^]int,left,right:int)->int{l:=tree[left];r:=tree[right];if l<0 do return r;if r<0 do return l;return if values[l]<=values[r] then l else r}
put_i64::proc "contextless"(out:[^]u8,offset:int,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{out[offset+b]=u8(bits>>u64(b*8))}}
@(export)
tournament_sort::proc "c"(input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<1||input[0]<0||input[0]>MAX_VALUES do return -1;n:=int(input[0]);if int(length)!=1+n do return -1
 values:[MAX_VALUES]i64;for i:=0;i<n;i+=1{if input[i+1]<(-2147483647-1)||input[i+1]>2147483647 do return -1;values[i]=input[i+1]}
 leaves:=1;for leaves<n do leaves*=2;tree:[2*MAX_VALUES+1]int;for i:=0;i<2*leaves;i+=1{tree[i]=-1};for i:=0;i<n;i+=1{tree[leaves+i]=i};for node:=leaves-1;node>=1;node-=1{tree[node]=choose(&values,&tree,node*2,node*2+1)}
 bytes:=(1+n)*8;if output==nil||int(capacity)<bytes do return -2;put_i64(output,0,i64(n));for out:=0;out<n;out+=1{w:=tree[1];put_i64(output,(1+out)*8,values[w]);pos:=leaves+w;tree[pos]=-1;for pos>1{pos/=2;tree[pos]=choose(&values,&tree,pos*2,pos*2+1)}};return i64(bytes)
}
