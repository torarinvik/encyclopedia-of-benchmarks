"""Independent oracle for the bounded natural-sort string format."""
MAX_INPUT_LENGTH = 4161
MAX_COUNT = 64

def expected_output(values):
    if not isinstance(values,(list,tuple)) or not 1<=len(values)<=MAX_INPUT_LENGTH:return -1,b""
    count=values[0]
    if type(count) is not int or not 0<=count<=MAX_COUNT:return -1,b""
    cursor=1;items=[]
    for _ in range(count):
        if cursor>=len(values):return -1,b""
        size=values[cursor];cursor+=1
        if type(size) is not int or not 0<=size<=64 or cursor+size>len(values):return -1,b""
        chars=values[cursor:cursor+size];cursor+=size
        if any(type(c) is not int or not 0<=c<128 for c in chars):return -1,b""
        text=bytes(chars).decode("ascii");digit=False
        for i,ch in enumerate(text):
            if "0"<=ch<="9":
                if i==0:return -1,b""
                digit=True
            elif ("A"<=ch<="Z" or "a"<=ch<="z") and not digit:pass
            else:return -1,b""
        prefix=next((i for i,ch in enumerate(text) if "0"<=ch<="9"),len(text))
        suffix=(0,0) if prefix==len(text) else (1,int(text[prefix:]))
        items.append((text[:prefix].lower(),suffix,text))
    if cursor!=len(values):return -1,b""
    items.sort(key=lambda x:(x[0],x[1]))
    output=b"\n".join(item[2].encode("ascii") for item in items)
    return len(output),output
