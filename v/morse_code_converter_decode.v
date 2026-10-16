module morse_code_converter_decode

const max_input_length = 512
const max_output_bytes = 512

fn morse_word(i int) i64 { if i==0{return 514};if i==1{return 1031};if i==2{return 1029};if i==3{return 771};if i==4{return 257};if i==5{return 1037};if i==6{return 769};if i==7{return 1039};if i==8{return 515};if i==9{return 1032};if i==10{return 770};if i==11{return 1035};if i==12{return 512};if i==13{return 513};if i==14{return 768};if i==15{return 1033};if i==16{return 1026};if i==17{return 773};if i==18{return 775};if i==19{return 256};if i==20{return 774};if i==21{return 1038};if i==22{return 772};if i==23{return 1030};if i==24{return 1028};if i==25{return 1027};return 0}
fn separator(text &i64,p int,end int) bool {unsafe{return p+2<end&&text[p]==32&&text[p+1]==124&&text[p+2]==32}}
fn decode_token(text &i64,start int,finish int) u8 {for letter in 0..26{word:=morse_word(letter);n:=int((word/256)%8);if finish-start!=n{continue};mask:=word%32;mut matches:=true;for bit in 0..n{shift:=n-bit-1;expected:=i64(45);if ((mask>>shift)&1)!=0{expected=46};if unsafe{text[start+bit]}!=expected{matches=false;break}};if matches{return u8(65+letter)}};return 63}
fn append_word(text &i64,start int,finish_value int,mut output &u8,mut written &int){if start==finish_value{unsafe{output[written[0]]=63};written[0]++;return};mut finish:=finish_value;for finish>start&&unsafe{text[finish-1]==32}{finish--};if start==finish{return};mut token:=start;for p in start..finish+1{if p==finish{unsafe{output[written[0]]=decode_token(text,token,p)};written[0]++}else if unsafe{text[p]==32}{unsafe{output[written[0]]=decode_token(text,token,p)};written[0]++;token=p+1}}}
fn decode(text &i64,length int,mut output &u8) int {if length==0{unsafe{output[0]=63};return 1};mut finish:=length;for finish>=3&&separator(text,finish-3,finish){finish-=3};if finish==0{return 0};mut written:=0;mut start:=0;mut p:=0;for p+2<finish{if separator(text,p,finish){append_word(text,start,p,mut output,mut written);unsafe{output[written]=32};written++;p+=3;start=p}else{p++}};append_word(text,start,finish,mut output,mut written);return written}

@[export: 'morse_code_converter_decode']
pub fn morse_code_converter_decode(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{if (input==nil&&length>0)||length>max_input_length{return -1};for i in 0..int(length){if input[i]<0||input[i]>127{return -1}};mut scratch:=[max_output_bytes]u8{};n:=decode(input,int(length),mut scratch[0]);if output==nil||capacity<usize(n){return -2};for i in 0..n{output[i]=scratch[i]};return i64(n)}}
