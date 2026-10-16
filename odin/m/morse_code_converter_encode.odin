package morse_code_converter_encode
import "core:c"

MAX_INPUT_LENGTH :: 512
MAX_OUTPUT_BYTES :: 2560
morse_word :: proc "contextless" (i:int)->i64 { if i==0 do return 514; if i==1 do return 1031; if i==2 do return 1029; if i==3 do return 771; if i==4 do return 257; if i==5 do return 1037; if i==6 do return 769; if i==7 do return 1039; if i==8 do return 515; if i==9 do return 1032; if i==10 do return 770; if i==11 do return 1035; if i==12 do return 512; if i==13 do return 513; if i==14 do return 768; if i==15 do return 1033; if i==16 do return 1026; if i==17 do return 773; if i==18 do return 775; if i==19 do return 256; if i==20 do return 774; if i==21 do return 1038; if i==22 do return 772; if i==23 do return 1030; if i==24 do return 1028; if i==25 do return 1027; return 0 }
letter_index :: proc "contextless" (value:i64)->int { if value>=65&&value<=90 do return int(value-65); if value>=97&&value<=122 do return int(value-97); return -1 }
append_word :: proc "contextless" (text:[^]i64,start,finish:int,out:[^]u8,written:^int){for p in start..finish{letter:=letter_index(text[p]);if letter>=0{word:=morse_word(letter);n:=int((word/256)%8);mask:=word%32;for bit in 0..n{shift:=n-bit-1;symbol:=u8(45);if ((mask>>shift)&1)!=0 do symbol=46;out[written^]=symbol;written^+=1}};out[written^]=32;written^+=1}}
encode :: proc "contextless" (text:[^]i64,length:int,out:[^]u8)->int{finish:=length;for finish>0&&text[finish-1]==32{finish-=1};if finish==0 do return 0;n:=0;start:=0;for p in 0..finish+1{if p==finish{append_word(text,start,p,out,&n)}else if text[p]==32{append_word(text,start,p,out,&n);out[n]=124;n+=1;out[n]=32;n+=1;start=p+1}};for n>0&&out[n-1]==32{n-=1};return n}
@(export)
morse_code_converter_encode :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if (input==nil&&length>0)||length>MAX_INPUT_LENGTH do return -1
 for i in 0..int(length){if input[i]<0||input[i]>127 do return -1}
 scratch:[MAX_OUTPUT_BYTES]u8;n:=encode(input,int(length),&scratch[0]);if output==nil||capacity<c.size_t(n) do return -2
 for i in 0..n{output[i]=scratch[i]};return i64(n)
}
