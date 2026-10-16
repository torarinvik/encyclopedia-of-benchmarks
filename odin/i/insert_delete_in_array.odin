package insert_delete_in_array
import "core:c"
@(export)
insert_delete_in_array :: proc "c" (v: [^]i64,n: c.size_t,output: [^]u8,capacity: c.size_t)->i64 {
 if v==nil||n<4||n>260 do return -1; op,len,pos,element:=v[0],v[1],v[2],v[3]
 if (op!=0&&op!=1)||len<0||len>256||n!=c.size_t(len+4)||pos<0 do return -1
 if (op==0&&pos>len)||(op==1&&pos>=len)||(op==1&&element!=0) do return -1
 for i:=0;i<int(len);i+=1 {if v[i+4]<i64(-2147483648)||v[i+4]>i64(2147483647) do return -1}
 if op==0&&(element<i64(-2147483648)||element>i64(2147483647)) do return -1
 outn:=int(len);if op==0 do outn+=1;if outn*4>int(capacity)||(outn>0&&output==nil) do return -2
 for i:=0;i<outn;i+=1 {x:=i64(0);if op==0 {if i<int(pos) do x=v[i+4] else if i==int(pos) do x=element else do x=v[i+3]}else{if i<int(pos) do x=v[i+4] else do x=v[i+5]};word:=u32(i32(x));output[i*4]=u8(word);output[i*4+1]=u8(word>>8);output[i*4+2]=u8(word>>16);output[i*4+3]=u8(word>>24)}
 return i64(outn*4)
}
