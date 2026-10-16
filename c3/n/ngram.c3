module ngram;
fn long ngram(long* v,usz n,char* out,usz cap) @export("ngram") {
 if(v==null||n<2||n>258||v[0]<1||v[0]>16||v[1]<0||v[1]>256||n!=(usz)v[1]+2)return -1;
 usz width=(usz)v[0],text=(usz)v[1];for(usz i=0;i<text;i++)if(v[i+2]<32||v[i+2]>126)return -1;
 usz grams=text>=width?text-width+1:0;usz bytes=grams>0?grams*width+grams-1:0;if(bytes>cap||(bytes>0&&out==null))return -2;
 usz w=0;for(usz i=0;i<grams;i++){if(i>0)out[w++]='\n';for(usz j=0;j<width;j++)out[w++]=(char)v[i+j+2];}return (long)w;
}
