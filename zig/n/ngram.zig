export fn ngram(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<2 or n>258)return -1;const width_raw=v[0];const text_raw=v[1];if(width_raw<1 or width_raw>16 or text_raw<0 or text_raw>256 or n!=@as(usize,@intCast(text_raw))+2)return -1;
 const width:usize=@intCast(width_raw);const text:usize=@intCast(text_raw);for(0..text)|i|{if(v[i+2]<32 or v[i+2]>126)return -1;}
 const grams:usize=if(text>=width)text-width+1 else 0;const bytes:usize=if(grams>0)grams*width+grams-1 else 0;if(bytes>cap)return -2;
 var w:usize=0;for(0..grams)|i|{if(i>0){out[w]=10;w+=1;}for(0..width)|j|{out[w]=@intCast(v[i+j+2]);w+=1;}}return @intCast(w);
}
