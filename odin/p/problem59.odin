package problem59
import "core:c"

MAX_CIPHER :: 4096
KEY_COUNT :: 17576
Key :: struct { bytes: [3]u8 }
allowed :: proc(value:i64)->bool{return(value>=9&&value<=13)||(value>=32&&value<=126)}
word_length :: proc(id:int)->int{return [3,2,2,2,3,2,4,4][id]}
word_char :: proc(id,j:int)->u8{words: [8]string={"the","be","to","of","and","in","that","have"};return words[id][j]}
lower_ascii :: proc(value:u8)->u8{return if value>=65&&value<=90 then value+32 else value}
contains_word :: proc(input:[^]i64,length:c.size_t,keys:[^]Key,index:int,id:int)->bool{
 width:=word_length(id);if int(length)<width do return false
 for start:=0;start+width<=int(length);start+=1{matched:=true;for j:=0;j<width;j+=1{pos:=start+j;ch:=lower_ascii(u8(input[pos])^keys[index].bytes[pos%3]);if ch!=word_char(id,j){matched=false;break}}if matched do return true}return false
}

@(export)
problem59 :: proc "c"(input:[^]i64,length:c.size_t)->i64{
 if input==nil||length==0||length>MAX_CIPHER do return -1
 for i:=c.size_t(0);i<length;i+=1{if input[i]<0||input[i]>255 do return -1}
 keys:[KEY_COUNT]Key;count:=0
 for a:=97;a<=122;a+=1{for b:=97;b<=122;b+=1{for c:=97;c<=122;c+=1{valid:=true;for i:=c.size_t(0);i<length;i+=1{k:=if i%3==0 then a else if i%3==1 then b else c;if !allowed(input[i]^i64(k)){valid=false;break}}if valid{keys[count].bytes=[3]u8{u8(a),u8(b),u8(c)};count+=1}}}}
 for id:=0;id<8;id+=1{kept:=0;for i:=0;i<count;i+=1{if contains_word(input,length,&keys[0],i,id){if kept!=i do keys[kept]=keys[i];kept+=1}}count=kept;if count==1 do break}
 if count==0 do return -1
 sum:=i64(0);for i:=c.size_t(0);i<length;i+=1{sum+=input[i]^i64(keys[0].bytes[i%3])};return sum
}
