module morse_code_converter_encode

const max_input_length = 512
const max_output_bytes = 2560

fn morse_word(i int) i64 { if i==0{return 514};if i==1{return 1031};if i==2{return 1029};if i==3{return 771};if i==4{return 257};if i==5{return 1037};if i==6{return 769};if i==7{return 1039};if i==8{return 515};if i==9{return 1032};if i==10{return 770};if i==11{return 1035};if i==12{return 512};if i==13{return 513};if i==14{return 768};if i==15{return 1033};if i==16{return 1026};if i==17{return 773};if i==18{return 775};if i==19{return 256};if i==20{return 774};if i==21{return 1038};if i==22{return 772};if i==23{return 1030};if i==24{return 1028};if i==25{return 1027};return 0}
fn letter_index(value i64) int { if value>=65&&value<=90{return int(value-65)};if value>=97&&value<=122{return int(value-97)};return -1 }
fn append_word(text &i64,start int,finish int,mut output &u8,mut written &int){for p in start..finish{letter:=letter_index(unsafe{text[p]});if letter>=0{word:=morse_word(letter);n:=int((word/256)%8);mask:=word%32;for bit in 0..n{shift:=n-bit-1;symbol:=u8(45);if ((mask>>shift)&1)!=0{symbol=46};unsafe{output[written[0]]=symbol};written[0]++}};unsafe{output[written[0]]=32};written[0]++}}
fn encode(text &i64,length int,mut output &u8) int {mut finish:=length;for finish>0&&unsafe{text[finish-1]==32}{finish--};if finish==0{return 0};mut written:=0;mut start:=0;for p in 0..finish+1{if p==finish{append_word(text,start,p,mut output,mut written)}else if unsafe{text[p]==32}{append_word(text,start,p,mut output,mut written);unsafe{output[written]=124;output[written+1]=32};written+=2;start=p+1}};for written>0&&unsafe{output[written-1]==32}{written--};return written}

@[export: 'morse_code_converter_encode']
pub fn morse_code_converter_encode(input &i64,length usize,mut output &u8,capacity usize)i64{unsafe{if (input==nil&&length>0)||length>max_input_length{return -1};for i in 0..int(length){if input[i]<0||input[i]>127{return -1}};mut scratch:=[max_output_bytes]u8{};n:=encode(input,int(length),mut scratch[0]);if output==nil||capacity<usize(n){return -2};for i in 0..n{output[i]=scratch[i]};return i64(n)}}
