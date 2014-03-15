library EDU05D;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  View-Project Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the DELPHIMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using DELPHIMM.DLL, pass string information
  using PChar or ShortString parameters. }  

uses
  SysUtils,
  Classes,
  EDU05DLL in 'EDU05DLL.pas',
  findpath in 'findpath.pas';

{$R *.RES}

exports
OpenDevice,
CloseDevice,
Connected,
ReadAnalogChannel,
SetPWM,
OutputAllDigital,
ClearDigitalChannel,
ClearAllDigital,
SetDigitalChannel,
SetAllDigital,
ReadDigitalChannel,
ReadAllDigital,
InOutMode,
LCDClear,
LCDWriteString,
StartupDemo,
ReadBackStartupDemo,
Test;

end.
 