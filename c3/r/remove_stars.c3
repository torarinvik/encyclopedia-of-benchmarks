module remove_stars;
const usz MAX_INPUT_LENGTH=4096;
fn long remove_stars(long* v,usz n,char* out,usz cap) @export("remove_stars") {
 if(v==null||n<1||n>MAX_INPUT_LENGTH+1||v[0]<0||v[0]>(long)MAX_INPUT_LENGTH||n!=1+(usz)v[0])return -1;
 usz result=0;for(usz i=0;i<(usz)v[0];i++){if(v[i+1]<0||v[i+1]>127)return -1;if(v[i+1]==42){if(result>0)result--;}else result++;}
 if(result>cap||(result>0&&out==null))return -2;usz w=0;for(usz i=0;i<(usz)v[0];i++){if(v[i+1]==42){if(w>0)w--;}else out[w++]=(char)v[i+1];}return (long)w;
}
