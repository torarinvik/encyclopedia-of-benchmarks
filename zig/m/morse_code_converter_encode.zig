const MAX_INPUT_LENGTH: usize = 512;
const MAX_OUTPUT_BYTES: usize = 2560;
fn morseWord(index: usize) i64 {
    const words = [_]i64{514,1031,1029,771,257,1037,769,1039,515,1032,770,1035,512,513,768,1033,1026,773,775,256,774,1038,772,1030,1028,1027};
    return words[index];
}
fn letterIndex(value: i64) i64 { if(value>=65 and value<=90)return value-65;if(value>=97 and value<=122)return value-97;return -1; }
fn appendWord(text:[*c]const i64,start:usize,finish:usize,out:*[MAX_OUTPUT_BYTES]u8,written:*usize) void {
    for(start..finish)|p|{const letter=letterIndex(text[p]);if(letter>=0){const word=morseWord(@intCast(letter));const n:usize=@intCast(@divTrunc(word,256)%8);const mask=@mod(word,32);for(0..n)|bit|{const shift=n-bit-1;const value=@mod(@divTrunc(mask,@as(i64,1)<<@intCast(shift)),2);out[written.*]=if(value!=0)46 else 45;written.*+=1;}}out[written.*]=32;written.*+=1;}
}
fn encode(text:[*c]const i64,length:usize,out:*[MAX_OUTPUT_BYTES]u8)usize{
    var finish=length;while(finish>0 and text[finish-1]==32)finish-=1;if(finish==0)return 0;
    var written:usize=0;var start:usize=0;for(0..finish+1)|p|{if(p==finish){appendWord(text,start,p,out,&written);}else if(text[p]==32){appendWord(text,start,p,out,&written);out[written]=124;written+=1;out[written]=32;written+=1;start=p+1;}}
    while(written>0 and out[written-1]==32)written-=1;return written;
}
export fn morse_code_converter_encode(input:[*c]const i64,length:usize,output:[*c]u8,capacity:usize)i64{
    if((input==null and length>0) or length>MAX_INPUT_LENGTH)return -1;for(0..length)|i|if(input[i]<0 or input[i]>127)return -1;
    var scratch:[MAX_OUTPUT_BYTES]u8=undefined;const written=encode(input,length,&scratch);if(output==null or capacity<written)return -2;@memcpy(output[0..written],scratch[0..written]);return @intCast(written);
}
