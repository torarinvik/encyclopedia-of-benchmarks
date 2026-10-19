from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin,UnsafePointer
comptime LZW_ITEMS=4096
comptime LZW_CODES=4352
comptime LZW_OUTPUT=65536
fn lzw_hash_byte(h:UInt64,b:UInt8)->UInt64:return (h^UInt64(b))*UInt64(1099511628211)
fn lzw_hash_word(mut h:UInt64,x:Int64):
    let b=UInt64(x)
    for j in range(8):h=lzw_hash_byte(h,UInt8((b>>(8*j))&255))
fn lzw_record_hash(mode:Int64,count:Int,values:InlineArray[Int64,LZW_ITEMS])->Int64:
    var h:UInt64=14695981039346656037;lzw_hash_word(h,mode);lzw_hash_word(h,Int64(count))
    for i in range(count):lzw_hash_word(h,values[i])
    return Int64(h&UInt64(0x7fffffffffffffff))
@export("lzw")
fn lzw(v:UnsafePointer[Int64,ImmutAnyOrigin],n:c_size_t) abi("C")->Int64:
    if v==UnsafePointer[Int64,ImmutAnyOrigin]() or n<2 or n>4098:return -1
    let mode=v[0];let count64=v[1]
    if (mode!=0 and mode!=1) or count64<0 or count64>4096 or n!=c_size_t(count64+2):return -1
    let count=Int(count64)
    var prefix=InlineArray[Int64,LZW_CODES](fill= -1);var sibling=InlineArray[Int64,LZW_CODES](fill= -1);var child=InlineArray[Int64,LZW_CODES](fill= -1);var suffix=InlineArray[Int64,LZW_CODES](fill=0);var first=InlineArray[Int64,LZW_CODES](fill=0)
    for i in range(256):suffix[i]=Int64(i);first[i]=Int64(i)
    if mode==0:
        for i in range(count):if v[i+2]<0 or v[i+2]>127:return -1
        var codes=InlineArray[Int64,LZW_ITEMS](fill=0);var nc=0
        if count>0:
            var size=256;var current=Int(v[2])
            for i in range(1,count):
                let byte=Int(v[i+2]);var match=Int(child[current])
                while match>=0 and suffix[match]!=Int64(byte):match=Int(sibling[match])
                if match>=0:current=match
                else:
                    codes[nc]=Int64(current);nc+=1
                    if size>=LZW_CODES:return -1
                    prefix[size]=Int64(current);suffix[size]=Int64(byte);first[size]=first[current];sibling[size]=child[current];child[current]=Int64(size);size+=1;current=byte
            codes[nc]=Int64(current);nc+=1
        return lzw_record_hash(0,nc,codes)
    for i in range(count):if v[i+2]<0 or v[i+2]>=LZW_CODES:return -1
    if count==0:
        var empty=InlineArray[Int64,LZW_ITEMS](fill=0);return lzw_record_hash(1,0,empty)
    let first_code=Int(v[2])
    if first_code>127:return -1
    var decoded=InlineArray[UInt8,LZW_OUTPUT](fill=UInt8(0));var phrase=InlineArray[UInt8,LZW_CODES](fill=UInt8(0));var decoded_n=1;decoded[0]=UInt8(first_code);var size=256;var previous=first_code
    for i in range(1,count):
        let code=Int(v[i+2]);var current=code;var phrase_n=0
        if code<size:
            while current>=256:
                if current>=size or phrase_n>=LZW_CODES:return -1
                phrase[phrase_n]=UInt8(suffix[current]);phrase_n+=1;current=Int(prefix[current])
                if current<0:return -1
            if current<0 or current>255 or phrase_n>=LZW_CODES:return -1
            phrase[phrase_n]=UInt8(current);phrase_n+=1
            for j in range(phrase_n//2):let t=phrase[j];phrase[j]=phrase[phrase_n-1-j];phrase[phrase_n-1-j]=t
        elif code==size:
            current=previous
            while current>=256:
                if current>=size or phrase_n>=LZW_CODES:return -1
                phrase[phrase_n]=UInt8(suffix[current]);phrase_n+=1;current=Int(prefix[current])
                if current<0:return -1
            if current<0 or current>255 or phrase_n>=LZW_CODES:return -1
            phrase[phrase_n]=UInt8(current);phrase_n+=1
            for j in range(phrase_n//2):let t=phrase[j];phrase[j]=phrase[phrase_n-1-j];phrase[phrase_n-1-j]=t
            if phrase_n>=LZW_CODES:return -1
            phrase[phrase_n]=UInt8(first[previous]);phrase_n+=1
        else:return -1
        if decoded_n>LZW_OUTPUT-phrase_n:return -1
        for j in range(phrase_n):
            if phrase[j]>127:return -1
            decoded[decoded_n]=phrase[j];decoded_n+=1
        if size>=LZW_CODES:return -1
        let next_byte=if code==size:first[previous] else:first[code]
        prefix[size]=Int64(previous);suffix[size]=Int64(next_byte);first[size]=first[previous];size+=1;previous=code
    var h:UInt64=14695981039346656037;lzw_hash_word(h,1);lzw_hash_word(h,Int64(decoded_n))
    for i in range(decoded_n):lzw_hash_word(h,Int64(decoded[i]))
    return Int64(h&UInt64(0x7fffffffffffffff))
