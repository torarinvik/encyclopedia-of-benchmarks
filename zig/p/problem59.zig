const MAX_CIPHER:usize=4096;const KEY_COUNT:usize=17576;
fn allowed(value:i64)bool{return(value>=9 and value<=13)or(value>=32 and value<=126);}
fn wordLength(id:usize)usize{return [3,2,2,2,3,2,4,4][id];}
fn wordChar(id:usize,j:usize)u8{const words=[_]([]const u8){"the","be","to","of","and","in","that","have"};return words[id][j];}
fn lowerAscii(value:u8)u8{return if(value>=65 and value<=90)value+32 else value;}
fn containsWord(input:[*]const i64,length:usize,keys:*[KEY_COUNT*3]u8,index:usize,id:usize)bool{
 const width=wordLength(id);if(length<width)return false;for(0..length-width+1)|start|{var matched=true;for(0..width)|j|{const pos=start+j;const value=@as(u8,@intCast(input[pos]))^keys[index*3+pos%3];if(lowerAscii(value)!=wordChar(id,j)){matched=false;break;}}if(matched)return true;}return false;
}
export fn problem59(input:[*c]const i64,length:usize)i64{
 if(input==null or length==0 or length>MAX_CIPHER)return -1;for(0..length)|i|if(input[i]<0 or input[i]>255)return -1;
 var keys=[_]u8{0}**(KEY_COUNT*3);var count:usize=0;
 for(97..123)|a|for(97..123)|b|for(97..123)|c|{var valid=true;for(0..length)|i|{const key=if(i%3==0)a else if(i%3==1)b else c;if(!allowed(input[i]^@as(i64,@intCast(key)))){valid=false;break;}}if(valid){keys[count*3]=@intCast(a);keys[count*3+1]=@intCast(b);keys[count*3+2]=@intCast(c);count+=1;}};
 for(0..8)|id|{var kept:usize=0;for(0..count)|i|{if(containsWord(input,length,&keys,i,id)){if(kept!=i){keys[kept*3]=keys[i*3];keys[kept*3+1]=keys[i*3+1];keys[kept*3+2]=keys[i*3+2];}kept+=1;}}count=kept;if(count==1)break;}
 if(count==0)return -1;var sum:i64=0;for(0..length)|i|sum+=input[i]^@as(i64,keys[i%3]);return sum;
}
