module insert_delete_in_array
@[export: 'insert_delete_in_array']
pub fn insert_delete_in_array(v &i64,n usize,output &u8,capacity usize)i64{
 if unsafe{v==nil}||n<4||n>260{return -1};op:=unsafe{v[0]};len:=unsafe{v[1]};pos:=unsafe{v[2]};element:=unsafe{v[3]}
 if(op!=0&&op!=1)||len<0||len>256||n!=int(len)+4||pos<0{return -1};if(op==0&&pos>len)||(op==1&&pos>=len)||(op==1&&element!=0){return -1}
 for i in 0..int(len){x:=unsafe{v[i+4]};if x< -2147483648||x>2147483647{return -1}};if op==0&&(element< -2147483648||element>2147483647){return -1}
 outn:=int(len);if op==0{outn++};if outn*4>capacity||(outn>0&&unsafe{output==nil}){return -2}
 for i in 0..outn{x:=i64(0);if op==0{if i<int(pos){x=unsafe{v[i+4]}}else if i==int(pos){x=element}else{x=unsafe{v[i+3]}}}else{if i<int(pos){x=unsafe{v[i+4]}}else{x=unsafe{v[i+5]}}};w:=u32(i32(x));unsafe{output[i*4]=u8(w);output[i*4+1]=u8(w>>8);output[i*4+2]=u8(w>>16);output[i*4+3]=u8(w>>24)}}
 return i64(outn*4)
}
