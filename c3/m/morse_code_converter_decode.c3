module morse_code_converter_decode;
const long MAX_INPUT_LENGTH=512;
const long MAX_OUTPUT_BYTES=512;
fn long morse_word(usz i){if(i==0)return 514;if(i==1)return 1031;if(i==2)return 1029;if(i==3)return 771;if(i==4)return 257;if(i==5)return 1037;if(i==6)return 769;if(i==7)return 1039;if(i==8)return 515;if(i==9)return 1032;if(i==10)return 770;if(i==11)return 1035;if(i==12)return 512;if(i==13)return 513;if(i==14)return 768;if(i==15)return 1033;if(i==16)return 1026;if(i==17)return 773;if(i==18)return 775;if(i==19)return 256;if(i==20)return 774;if(i==21)return 1038;if(i==22)return 772;if(i==23)return 1030;if(i==24)return 1028;if(i==25)return 1027;return 0;}
fn bool separator(long* text,usz p,usz end){return p+2<end&&text[p]==' '&&text[p+1]=='|'&&text[p+2]==' ';}
fn char decode_token(long* text,usz start,usz end){for(usz l=0;l<26;l++){long word=morse_word(l);usz len=(usz)((word/256)%8);if(end-start!=len)continue;long mask=word%32;bool same=true;for(usz b=0;b<len;b++){usz shift=len-b-1;long expected=((mask>>shift)&1)!=0?'.':'-';if(text[start+b]!=expected){same=false;break;}}if(same)return(char)('A'+l);}return '?';}
fn void append_word(long* text,usz start,usz finish,char* out,usz* n){if(start==finish){out[(*n)++]='?';return;}usz end=finish;while(end>start&&text[end-1]==' ')end--;if(start==end)return;usz token=start;for(usz p=start;p<=end;p++){if(p==end||text[p]==' '){out[(*n)++]=decode_token(text,token,p);token=p+1;}}}
fn usz decode(long* text,usz length,char* out){if(length==0){out[0]='?';return 1;}usz end=length;while(end>=3&&separator(text,end-3,end))end-=3;if(end==0)return 0;usz n=0,start=0,p=0;while(p+2<end){if(separator(text,p,end)){append_word(text,start,p,out,&n);out[n++]=' ';p+=3;start=p;}else p++;}append_word(text,start,end,out,&n);return n;}
fn long morse_code_converter_decode(long* input,usz length,char* output,usz capacity) @export("morse_code_converter_decode"){
 if((input==null&&length>0)||length>MAX_INPUT_LENGTH)return -1;for(usz i=0;i<length;i++)if(input[i]<0||input[i]>127)return -1;
 char[MAX_OUTPUT_BYTES] scratch;usz n=decode(input,length,&scratch[0]);if(output==null||capacity<n)return -2;for(usz i=0;i<n;i++)output[i]=scratch[i];return(long)n;
}
