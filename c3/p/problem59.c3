module problem59;
const usz MAX_CIPHER=4096; const usz KEY_COUNT=17576;
fn bool allowed(int value){return (value>=9&&value<=13)||(value>=32&&value<=126);}
fn int word_length(int id){int[8] lens={3,2,2,2,3,2,4,4};return lens[(usz)id];}
fn int word_char(int id,int j){char*[8] words={"the","be","to","of","and","in","that","have"};return (int)words[(usz)id][(usz)j];}
fn int lower_ascii(int value){return value>=65&&value<=90?value+32:value;}
fn bool contains_word(long* input,usz length,uchar* keys,usz index,int word){int width=word_length(word);if(length<(usz)width)return false;for(usz start=0;start+(usz)width<=length;start++){bool matched=true;for(int j=0;j<width;j++){usz pos=start+(usz)j;int key=keys[index*3+pos%3];if(lower_ascii((int)input[pos]^key)!=word_char(word,j)){matched=false;break;}}if(matched)return true;}return false;}
fn long problem59(long* input,usz length) @export("problem59"){
 if(input==null||length==0||length>MAX_CIPHER)return -1;for(usz i=0;i<length;i++)if(input[i]<0||input[i]>255)return -1;
 uchar[KEY_COUNT*3] keys;usz count=0;
 for(int a=97;a<=122;a++)for(int b=97;b<=122;b++)for(int c=97;c<=122;c++){bool valid=true;for(usz i=0;i<length;i++){int key=i%3==0?a:i%3==1?b:c;if(!allowed((int)input[i]^key)){valid=false;break;}}if(valid){keys[count*3]=(uchar)a;keys[count*3+1]=(uchar)b;keys[count*3+2]=(uchar)c;count++;}}
 for(int word=0;word<8;word++){usz kept=0;for(usz i=0;i<count;i++)if(contains_word(&input[0],length,&keys[0],i,word)){if(kept!=i){keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2];}kept++;}count=kept;if(count==1)break;}
 if(count==0)return -1;long sum=0;for(usz i=0;i<length;i++)sum+=input[i]^keys[i%3];return sum;
}
