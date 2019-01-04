{###############################################################################
#                                                                              #
# Unit:        HashCryptoAPILib.pas                                            #
# Date:        2010                                                            #
# Written by:  alexey-m                                                        #
# E-mail:      admin@alexey-m.ru                                               #
# Description: Getting the hashes (md2, md4, md5, sha1, crc32)                 #
#              by means of CryptoAPI Library;                                  #
#                                                                              #
################################################################################}
unit HashCryptoAPILib;

interface

uses
  Windows;

const
  HP_HASHVAL           = $0002; {hash value}
  PROV_RSA_FULL        = 1;
  CRYPT_VERIFYCONTEXT  = $F0000000;
type
  THashType = (
    ALG_CRC32 = $0001,
    ALG_MD2 = $8001,
    ALG_MD4 = $8002,
    ALG_MD5 = $8003,
    ALG_SHA = $8004);

function GetHash(Data: Pointer; var nSize: Cardinal; HashType: THashType): Pointer; forward;
function BinToHexStr(Bin: Pointer; nSize: Cardinal): String; forward;
function FileToHash(const FileName: String; var dwSize: Cardinal; HashType: THashType): Pointer; forward;

implementation

function CryptAcquireContext(var phProv: DWORD;
  pszContainer, pszProvider: LPCSTR; dwProvType, dwFlags: DWORD): BOOL;
  stdcall; external advapi32 name 'CryptAcquireContextA';
function CryptCreateHash(hProv,Algid,hKey,dwFlags: DWORD;
  var phHash: DWORD): BOOL; stdcall; external advapi32;
function CryptHashData(hHash: DWORD; pbData: PBYTE; dwDataLen,
  dwFlags: DWORD): BOOL; stdcall; external advapi32;
function CryptGetHashParam(hHash, dwParam: DWORD; pbData: PBYTE;
  var pdwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall; external advapi32;
function CryptDestroyHash(hHash: DWORD): BOOL; stdcall; external advapi32;
function CryptReleaseContext(hProv: DWORD; dwFlags: DWORD): BOOL; stdcall; external advapi32;

//==============================================================================
//      CryptoAPI Get hash (md2, md4, md5, sha1) Function
//==============================================================================

function GetHashs(Data: Pointer; var nSize: Cardinal; HashType: Cardinal): Pointer;
var
  hProv, hHash: Cardinal;
begin
  Result:= nil;
  if CryptAcquireContext(hProv, nil, nil, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT) then try
    if CryptCreateHash(hProv, HashType, 0, 0, hHash) then try
      if CryptHashData(hHash, Data, nSize, 0) then begin
        if CryptGetHashParam(hHash, HP_HASHVAL, nil, nSize, 0) then begin
          GetMem(Result, nSize);
          if not CryptGetHashParam(hHash, HP_HASHVAL, Result, nSize, 0) then begin
            FreeMem(Result);
            Result:= nil;
          end;
        end;
      end;
    finally
      CryptDestroyHash(hHash);
    end;
  finally
    CryptReleaseContext(hProv, 0);
  end;
end;

// Code is not from the "fast" but compact
function GetCRC32(szBlock: DWORD; Block: Pointer): DWORD; assembler;
asm
(*
  ; IN
  ; ESI = block offset
  ; EDI = block size
  ; OUT
  ; EAX = CRC32
*)
  push esi
  push edi
  push ecx
  push ebx
  mov edi,eax		// szBlock
  mov esi,edx		// Block
  cld
  xor ecx,ecx
  dec ecx
  mov edx,ecx
@@NextByteCRC:
  xor eax,eax
  xor ebx,ebx
  lodsb
  xor al,cl
  mov cl,ch
  mov ch,dl
  mov dl,dh
  mov dh,8
@@NextBitCRC:
  shr bx,1
  rcr ax,1
  jnc @@NoCRC
  xor ax,08320h
  xor bx,0EDB8h
@@NoCRC:
  dec dh
  jnz @@NextBitCRC
  xor ecx,eax
  xor edx,ebx
  dec edi
jnz @@NextByteCRC
  not edx
  not ecx
  mov eax,edx
  rol eax,16
  mov ax,cx
  bswap eax
  pop ebx
  pop ecx
  pop edi
  pop esi
end;

function GetHash(Data: Pointer; var nSize: Cardinal; HashType: THashType): Pointer;
begin
  case HashType of
    ALG_CRC32:
      begin
        GetMem(Result, 4);
        Cardinal(Result^):= GetCRC32(nSize, Data);
        nSize:= 4;
      end;
    else Result:= GetHashs(Data, nSize, Ord(HashType));
  end;
end;

function FileToHash(const FileName: String; var dwSize: Cardinal; HashType: THashType): Pointer;
var
  hFile,hMapFile: THandle;
  lpMemory: pointer;
begin
  Result:= nil; dwSize:= 0;

  hFile:= CreateFile(PChar(FileName),
                     GENERIC_READ,
                     FILE_SHARE_READ or FILE_SHARE_WRITE,
                     nil,
                     OPEN_EXISTING,
                     FILE_ATTRIBUTE_NORMAL or FILE_FLAG_SEQUENTIAL_SCAN,
                     0);

  if hFile <> INVALID_HANDLE_VALUE then try
    hMapFile:= CreateFileMapping(hFile, nil, PAGE_READONLY, 0, 0, nil);
    if hMapFile <> 0 then try
      lpMemory:= MapViewOfFile(hMapFile, FILE_MAP_READ, 0, 0, 0);
      if lpMemory <> nil then try
        dwSize:= GetFileSize(hFile, nil);
        Result:= GetHash(lpMemory, dwSize, HashType);
      finally
        UnmapViewOfFile(lpMemory);
      end;
    finally
      CloseHandle(hMapFile);
    end;
  finally
    CloseHandle(hFile);
  end;
end;

function BinToHexStr(Bin: Pointer; nSize: Cardinal): String;
var
  i: Cardinal;
  bt: Byte;
const
  Hex = '0123456789abcdef';
begin
  Result:= '';
  for i:= 0 to nSize - 1 do begin
    bt:= PByte(Ptr(Cardinal(Bin) + i))^;
    Result:= Result + Hex[bt shr $4 + 1] + Hex[bt and $0f + 1]
  end;
end;
            

end.
