unit EDU05DLL;

interface
uses
  Windows;

function OpenDevice: integer ; stdcall;
procedure CloseDevice; stdcall;
function ReadAnalogChannel(Channel: integer):integer; stdcall;
procedure SetPWM(Channel: integer; Data: integer); stdcall;
procedure OutputAllDigital(Data: integer); stdcall;
procedure ClearDigitalChannel(Channel: integer); stdcall;
procedure ClearAllDigital; stdcall;
procedure SetDigitalChannel(Channel: integer);  stdcall;
procedure SetAllDigital; stdcall;
function ReadDigitalChannel(Channel: integer): Boolean; stdcall;
function ReadAllDigital: integer; stdcall;
procedure InOutMode(IOMode: integer);   stdcall;
procedure LCDInit; stdcall;
procedure LCDClear; stdcall;
procedure LCDWriteString(data: pointer; Position: integer); stdcall;
procedure StartupDemo(onoff: integer); stdcall;
function ReadBackStartupDemo: boolean; stdcall;
function Connected: boolean; stdcall;

procedure OutIn(Tx:integer; Rx:integer);

function Reverse(data: integer):integer;
function Test: integer; stdcall;

var
  open: boolean;
  send_buf:array[0..64] of byte;
  receive_buf:array[0..64] of byte;
  hDeviceWrite: THandle;
  hDeviceRead: THandle;
  temp: DWORD;

implementation

uses findpath;

function OpenDevice: integer; stdcall;
begin
  CloseDevice;
  result:=givepath;
end;

procedure CloseDevice; stdcall;
var i:integer;
begin
  if open then
  begin
    CloseHandle(hDeviceWrite);
    CloseHandle(hDeviceRead);
    open:=false;
  end;
end;

function ReadAnalogChannel(Channel: integer):integer; stdcall;
begin
    send_buf[0] := 0;   //READ_ANALOG_CH
    if Channel>5 then Channel:=5;
    if Channel<1 then Channel:=1;
    case Channel of
      1: send_buf[1] := 2;
      2: send_buf[1] := 1;
      3: send_buf[1] := 0;
      4: send_buf[1] := 4;
      5: send_buf[1] := 3;
    end;
    OutIn(1,1);
    result:=receive_buf[1]+256*receive_buf[2];
end;


function Connected: boolean; stdcall;
begin
  send_buf[0] := 1;            // Connected
  send_buf[1] := 5;
  OutIn(1,1);
  if  receive_buf[1]=6 then
    result:=true
  else
    result:=false;
end;

procedure SetPWM(Channel: integer; Data: integer); stdcall;
begin
    send_buf[0] := 2;  // SET_PWM
    if Channel>2 then Channel:=2;
    if Channel<1 then Channel:=1;
    send_buf[1] := Channel-1;   // ch
    send_buf[2] := Data;   // data
    OutIn(1,0);
end;

function ReadAllDigital: integer; stdcall;
begin
    send_buf[0] := 4;  //READ_DIGITAL_BYTE
    OutIn(1,1);
    result:=Reverse(receive_buf[1]);
end;

function ReadDigitalChannel(Channel: integer): Boolean; stdcall;
var b:byte;
begin
    send_buf[0] := 4;  //READ_DIGITAL_BYTE
    OutIn(1,1);
    if Channel>8 then Channel:=8;
    if Channel<1 then Channel:=1;
    b:=1;
    b:=b shl (Channel-1);
    result:=((Reverse(receive_buf[1]) and b)>0);
end;

procedure OutputAllDigital(Data: integer); stdcall;
begin
    send_buf[0] := 5;  //OUT_DIGITAL_BYTE
    send_buf[1] := Reverse(Data);
    OutIn(1,0);
end;

procedure ClearAllDigital; stdcall;
begin
    send_buf[0] := 5;  //OUT_DIGITAL_BYTE
    send_buf[1] := 0;
    OutIn(1,0);
end;

procedure SetAllDigital; stdcall;
begin
    send_buf[0] := 5;  //OUT_DIGITAL_BYTE
    send_buf[1] := 255;
    OutIn(1,0);
end;

procedure ClearDigitalChannel(Channel: integer); stdcall;
var k:integer;
begin
  if Channel>8 then Channel:=8;
  if Channel<1 then Channel:=1;
  k:=255-round(Exp((Channel-1)*ln(2)));
  send_buf[0] := 6;  // Clear Digital Channel
  send_buf[1] := Reverse(k);
  OutIn(1,0);
end;

procedure SetDigitalChannel(Channel: integer);   stdcall;
var k:integer;
begin
  if Channel>8 then Channel:=8;
  if Channel<1 then Channel:=1;
  k:=round(Exp((Channel-1)*ln(2)));
  send_buf[0] := 7;  // Set Digital Channel
  send_buf[1] := Reverse(k);
  OutIn(1,0);
end;

procedure InOutMode(IOMode: integer);   stdcall;
begin
  send_buf[0] := 8;  // In_Out_Mode
  send_buf[1] := IOMode;
  OutIn(1,0);
end;

procedure LCDInit; stdcall;
begin
  send_buf[0] := 9;  // LCDInit
  OutIn(1,0);
end;

procedure LCDClear; stdcall;
begin
  send_buf[0] := 10;  //   LCDClear
  OutIn(1,0);
end;

procedure LCDWriteString(Data: pointer; Position: integer); stdcall;
var p:^byte;
s:string[20];
i:integer;
begin
  send_buf[0] := 11;  //    LCDWriteString
  p:=Data;
  i:=0;
  repeat
    send_buf[1]:=p^;
    send_buf[2]:=0;
    send_buf[3]:=i+position;
    inc(i);
    inc(p);
    OutIn(1,0);
  until p^=0;
end;

procedure StartupDemo(onoff: integer); stdcall;
begin
  send_buf[0] := 12;            // StartupDemo
  send_buf[1] := onoff;         // 0 = 0ff, 0xFF = on
  OutIn(1,0);
end;

function ReadBackStartupDemo: boolean; stdcall;
begin
  send_buf[0] := 13;            // ReadBack StartupDemo
  OutIn(1,1);
  if  receive_buf[1]=0 then
    result:=true
  else
    result:=false;
end;


procedure OutIn(Tx:integer; Rx:integer);
var BytesWritten, BytesRead:DWORD;
i:integer;
buf_Tx:array[0..8] of byte;
buf_Rx:array[0..8] of byte;
begin
  for i:=0 to 8 do
  begin
    buf_Tx[i+1]:=send_buf[i];
    buf_Rx[i]:=0;
    receive_buf[i]:=0;
  end;
  buf_Tx[0]:=0;
  BytesRead:=0;
  if open and (Tx>0) then
  begin
    WriteFile(hDeviceWrite,buf_Tx,8,BytesWritten,nil);
    if BytesWritten=0 then
    begin
      open:=false;
      CloseHandle(hDeviceWrite);
      CloseHandle(hDeviceRead);
    end;
  end;
  if open and (Rx>0) then
  begin
    ReadFile(hDeviceRead,buf_Rx,8,BytesRead,nil);
    for i:=0 to 8 do
      receive_buf[i]:=buf_Rx[i+1];
    if BytesRead=0 then
    begin
      open:=false;
      CloseHandle(hDeviceWrite);
      CloseHandle(hDeviceRead);
    end;
  end;
end;


function Reverse(data: integer):integer;
var a: byte;
begin
  a:=data;
    asm
       mov        ecx,8
       mov        al,a
    @loop1:   
       rcl        al,1
       rcr        ah,1
       loop       @loop1
       mov        a,ah
    end;
    result:=a;
end;

function Test: integer; stdcall;
begin
      //  temp:=0;
     //   send_buf[0]:=8;
    //WriteFile(hDeviceWrite,send_buf[0],8,temp,nil);
    if open then
        result:=0
    else
        result:=1
end;

initialization
    open:=false;
    hDeviceWrite:= INVALID_HANDLE_VALUE; //Should be invalid before init.
    hDeviceRead:= INVALID_HANDLE_VALUE; //Should be invalid before init.
end.
