@export("gray_to_binary")
fn gray_to_binary(gray0:Int64) abi("C")->Int64:
    if gray0<0:return -1
    var gray=gray0;var binary=gray;gray>>=1
    while gray!=0:binary^=gray;gray>>=1
    return binary
