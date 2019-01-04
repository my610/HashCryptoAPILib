# HashCryptoAPILib

### Функция возвращающая хэш сумму для блока памяти:

```pas
function GetHash(Data: Pointer; var nSize: Cardinal; HashType: THashType): Pointer;
```

**Data** [in] - указатель на буфер, для которого высчитывается хэш сумма;

**nSize** [in,out] - размер буфера с данными, после выполнения функции, данной переменной присваивается размер данных хэш суммы;

**HashType** [in] - тип высчитываемой хэш суммы (**MD2**, **MD4**, **MD5**, **SHA1**, **CRC32**).

### Вывод хэш суммы в текстовом формате:

```pas
function BinToHexStr(Bin: Pointer; nSize: Cardinal): String;
```

**Bin** [in] - указатель на буфер с полученной хэш суммой;

**nSize** [in] - размер буфера с хэш суммой.

### Функция возвращающая хэш сумму для файла:

```pas
function FileToHash(const FileName: String; var dwSize: Cardinal; HashType: THashType): Pointer;
```

**FileName** [in] - имя файла, для которого высчитывается хэш сумма;

**dwSize** [out] - данной переменной присваивается размер данных хэш суммы;

**HashType** [in] - тип высчитываемой хэш суммы (**MD2**, **MD4**, **MD5**, **SHA1**, **CRC32**).

## Примеры

Для строки (блока памяти):

```pas
procedure TForm1.Button1Click(Sender: TObject);
var
  digest: Pointer;
  dwSize: Cardinal;
  Str: String;
begin
  Str:= 'bla-bla-bla';
  dwSize:= Length(Str);
  digest:= GetHash(@Str[1], dwSize, ALG_MD5);
  if digest <> nil then try
    Str:= BinToHexStr(digest, dwSize);
    ShowMessage(Str);
  finally
    FreeMem(digest);
  end;
end;
```

Для файла:

```pas
procedure TForm1.Button1Click(Sender: TObject);
var
  digest: Pointer;
  dwSize: Cardinal;
  Str: String;
begin
  Str:= 'c:\test.txt';
  digest:= FileToHash(Str, dwSize, ALG_MD5);
  if digest <> nil then try
    Str:= BinToHexStr(digest, dwSize);
    ShowMessage(Str);
  finally
    FreeMem(digest);
  end;
end;
```

License
----

MIT
