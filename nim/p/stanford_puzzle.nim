# Independent bounded implementation of Stanford Puzzle, attributed in the
# pinned file to Forest Baskett. No upstream code/comments are copied; the
# pinned source has no explicit redistribution grant.
const
  Side = 5
  CellCount = 125
  TypeCount = 13
  MaxSearchCalls = 2005
  HoleScale = 1_000_000'i64

type Piece = object
  x, y, z, pieceClass: int

const Pieces: array[TypeCount, Piece] = [
  Piece(x:4,y:2,z:1,pieceClass:0),Piece(x:2,y:1,z:4,pieceClass:0),
  Piece(x:1,y:4,z:2,pieceClass:0),Piece(x:2,y:4,z:1,pieceClass:0),
  Piece(x:4,y:1,z:2,pieceClass:0),Piece(x:1,y:2,z:4,pieceClass:0),
  Piece(x:3,y:1,z:1,pieceClass:1),Piece(x:1,y:3,z:1,pieceClass:1),Piece(x:1,y:1,z:3,pieceClass:1),
  Piece(x:2,y:2,z:1,pieceClass:2),Piece(x:2,y:1,z:2,pieceClass:2),Piece(x:1,y:2,z:2,pieceClass:2),
  Piece(x:2,y:2,z:2,pieceClass:3)
]

proc fits(board: array[CellCount,bool], start, kind: int): bool =
  let x0=start mod Side; let y0=(start div Side) mod Side; let z0=start div (Side*Side)
  let p=Pieces[kind]
  if x0+p.x>Side or y0+p.y>Side or z0+p.z>Side: return false
  for z in 0..<p.z:
    for y in 0..<p.y:
      for x in 0..<p.x:
        if board[(z0+z)*Side*Side+(y0+y)*Side+x0+x]: return false
  true

proc mark(board: var array[CellCount,bool], start, kind: int, value: bool) =
  let x0=start mod Side; let y0=(start div Side) mod Side; let z0=start div (Side*Side)
  let p=Pieces[kind]
  for z in 0..<p.z:
    for y in 0..<p.y:
      for x in 0..<p.x:
        board[(z0+z)*Side*Side+(y0+y)*Side+x0+x]=value

proc firstEmpty(board: array[CellCount,bool], startIndex: int): int =
  for i in startIndex..<CellCount:
    if not board[i]: return i
  0

proc sourceIndex(flat: int): int64 =
  let x=flat mod Side; let y=(flat div Side) mod Side; let z=flat div (Side*Side)
  int64(x+1)+8*int64(y+1)+64*int64(z+1)

proc search(board: var array[CellCount,bool], remaining: var array[4,int], start: int,
            calls: var int, overflow: var bool): bool =
  inc calls
  if calls>MaxSearchCalls: overflow=true; return false
  for kind in 0..<TypeCount:
    let cls=Pieces[kind].pieceClass
    if remaining[cls]==0 or not fits(board,start,kind): continue
    mark(board,start,kind,true); dec remaining[cls]
    let next=firstEmpty(board,start)
    let child=search(board,remaining,next,calls,overflow)
    if overflow: return false
    if child or next==0: return true
    inc remaining[cls]; mark(board,start,kind,false)
  false

proc stanford_puzzle*(input: ptr UncheckedArray[int64], length: csize_t): int64 {.cdecl, exportc: "stanford_puzzle".} =
  if input==nil or length!=1 or input[0]<1 or input[0]>100: return -1
  var checksum=0'i64
  for pass in 0..<int(input[0]):
    var board: array[CellCount,bool]
    var remaining=[13,3,1,1]
    if not fits(board,0,0): return -1
    mark(board,0,0,true); dec remaining[0]
    let hole=firstEmpty(board,0)
    var calls=0; var overflow=false
    if hole==0 or not search(board,remaining,hole,calls,overflow) or overflow: return -1
    checksum+=sourceIndex(hole)*HoleScale+int64(calls)
  checksum
