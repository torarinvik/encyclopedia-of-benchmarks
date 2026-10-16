module morse_code_converter_encode;
const long MAX_INPUT_LENGTH=512;
const long MAX_OUTPUT_BYTES=2560;
fn long morse_word(usz i){if(i==0)return 514;if(i==1)return 1031;if(i==2)return 1029;if(i==3)return 771;if(i==4)return 257;if(i==5)return 1037;if(i==6)return 769;if(i==7)return 1039;if(i==8)return 515;if(i==9)return 1032;if(i==10)return 770;if(i==11)return 1035;if(i==12)return 512;if(i==13)return 513;if(i==14)return 768;if(i==15)return 1033;if(i==16)return 1026;if(i==17)return 773;if(i==18)return 775;if(i==19)return 256;if(i==20)return 774;if(i==21)return 1038;if(i==22)return 772;if(i==23)return 1030;if(i==24)return 1028;if(i==25)return 1027;return 0;}
fn long letter_index(long value){if(value>='A'&&value<='Z')return value-'A';if(value>='a'&&value<='z')return value-'a';return -1;}
fn void append_word(long* text,usz start,usz end,char* out,usz* n){for(usz p=start;p<end;p++){long letter=letter_index(text[p]);if(letter>=0){long word=morse_word((usz)letter);usz len=(usz)((word/256)%8);long mask=word%32;for(usz bit=0;bit<len;bit++){usz shift=len-bit-1;out[(*n)++]=(char)(((mask>>shift)&1)!=0?'.':'-');}}out[(*n)++]=' ';}}
fn usz encode(long* text,usz length,char* out){usz end=length;while(end>0&&text[end-1]==' ')end--;if(end==0)return 0;usz n=0,start=0;for(usz p=0;p<=end;p++){if(p==end||text[p]==' '){append_word(text,start,p,out,&n);if(p<end){out[n++]='|';out[n++]=' ';}start=p+1;}}while(n>0&&out[n-1]==' ')n--;return n;}
fn long morse_code_converter_encode(long* input,usz length,char* output,usz capacity) @export("morse_code_converter_encode"){
 if((input==null&&length>0)||length>MAX_INPUT_LENGTH)return -1;for(usz i=0;i<length;i++)if(input[i]<0||input[i]>127)return -1;
 char[MAX_OUTPUT_BYTES] scratch;usz n=encode(input,length,&scratch[0]);if(output==null||capacity<n)return -2;for(usz i=0;i<n;i++)output[i]=scratch[i];return(long)n;
}
