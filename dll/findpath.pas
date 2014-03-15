unit findpath;

interface
uses
    Windows, SysUtils;
type
   HDEVINFO = Pointer;
   SP_DEVINFO_DATA = record
      cbSize: DWord;
      Guid: TGUID;
      DevInst: DWord;
      Reserve: DWord;
    end;
    PSP_DEVINFO_DATA = ^SP_DEVINFO_DATA;

    SP_DEVICE_INTERFACE_DETAIL_DATA = packed record
      cbSize:DWORD  ;
      DevicePath: array [0..0] of AnsiChar;
   end;
   PSP_DEVICE_INTERFACE_DETAIL_DATA  = ^SP_DEVICE_INTERFACE_DETAIL_DATA;

   SP_DEVICE_INTERFACE_DATA = record
      cbSize: DWORD  ;
      InterfaceClassGuid:TGUID  ;
      Flags:DWORD;
      Reserved:Pointer;
  end;
 PSP_DEVICE_INTERFACE_DATA  = ^SP_DEVICE_INTERFACE_DATA;


const
DIGCF_PRESENT = DWORD($00000002);
DIGCF_DEVICEINTERFACE = DWORD($00000010);

function givepath:integer;

var
  res1,res2,res3:Boolean;
  RequiredSize:DWord;
  DeviceInfoSet:HDEVINFO;
  DeviceInterfaceData:SP_DEVICE_INTERFACE_DATA;
  DEVICE_INTERFACE_DETAIL_DATA:PSP_DEVICE_INTERFACE_DETAIL_DATA;

implementation

uses EDU05DLL;

function SetupDiGetClassDevsA(ClassGuid: PGUID;Enumerator: PCHAR;hwndParent: HWND;Flags: DWORD): HDEVINFO; stdcall; external 'setupapi.dll';

function SetupDiGetDeviceInterfaceDetailA(
                   DeviceInfoSet: HDEVINFO;
                   DeviceInterfaceData:PSP_DEVICE_INTERFACE_DATA;
                   DeviceInterfaceDetailData:PSP_DEVICE_INTERFACE_DETAIL_DATA;
                   DeviceInterfaceDetailDataSize: DWORD;
                   RequiredSize:PDWORD;
                   DeviceInfoData:PSP_DEVINFO_DATA
                   ): Bool; stdcall; external 'setupapi.dll';

function SetupDiDestroyDeviceInfoList(DeviceInfoSet: HDEVINFO): Bool; stdcall; external 'setupapi.dll';

function SetupDiEnumDeviceInterfaces(
                   DeviceInfoSet:HDEVINFO;
                   DeviceInfoData: PSP_DEVINFO_DATA;
                   InterfaceClassGuid:PGUID;
                   MemberIndex:DWORD;
                   DeviceInterfaceData: PSP_DEVICE_INTERFACE_DATA
                   ): Bool; stdcall; external 'setupapi.dll';


function givepath:integer;
        const myGUID: TGuid = '{4d1e55b2-f16f-11cf-88cb-001111000030}';
        //'{58D07210-27C1-11DD-BD0B-0800200C9a66}';

        var MemberIndex:DWORD;
        DevicePath:PChar;
        tmp:integer;
        begin
                RequiredSize:=0;
                tmp:=0;
                //**********************************
                // Retrive DeviceInfoSet to be used for enumeration

                // Retrieves a device information set for a specified group of devices.
                // SetupDiEnumDeviceInterfaces uses the device information set.

                // parameters
                // Interface class GUID.
                // Null to retrieve information for all device instances.
                // Optional handle to a top-level window (unused here).
                // Flags to limit the returned information to currently present devices
                // and devices that expose interfaces in the class specified by the GUID.

                // Returns
                // Handle to a device information set for the devices.
                //**********************************

                DeviceInfoSet:=SetupDiGetClassDevsA(@myGUID,nil,0,(DIGCF_PRESENT or DIGCF_DEVICEINTERFACE));

                //**********************************
                // Enumerate all available interfaces
                // Retrieves a handle to a SP_DEVICE_INTERFACE_DATA structure for a device.
                // On return, MyDeviceInterfaceData contains the handle to a
                // SP_DEVICE_INTERFACE_DATA structure for a detected device.

                // parameters
                // DeviceInfoSet returned by SetupDiGetClassDevs.
                // Optional SP_DEVINFO_DATA structure that defines a device instance
                // that is a member of a device information set.
                // Device interface GUID.
                // Index to specify a device in a device information set.
                // Pointer to a handle to a SP_DEVICE_INTERFACE_DATA structure for a device.

                // Returns
                // True on success.
                //**********************************

                DeviceInterfaceData.cbSize:=sizeof(SP_DEVICE_INTERFACE_DATA);
                MemberIndex:=0;
                while(true) do
                        begin
                                res1:=SetupDiEnumDeviceInterfaces(DeviceInfoSet,nil,@myGUID,MemberIndex,@DeviceInterfaceData);
                                if (not res1) then
                                        break;

                                //*************************************************
                                //Determine the required size of the buffer and allocate the memory
                                // Retrieves an SP_DEVICE_INTERFACE_DETAIL_DATA structure
                                // containing information about a device.
                                // To retrieve the information, call this function twice.
                                // The first time returns the size of the structure.
                                // The second time returns a pointer to the data.

                                // parameters
                                // DeviceInfoSet returned by SetupDiGetClassDevs
                                // SP_DEVICE_INTERFACE_DATA structure returned by SetupDiEnumDeviceInterfaces
                                // A returned pointer to an SP_DEVICE_INTERFACE_DETAIL_DATA
                                // Structure to receive information about the specified interface.
                                // The size of the SP_DEVICE_INTERFACE_DETAIL_DATA structure.
                                // Pointer to a variable that will receive the returned required size of the
                                // SP_DEVICE_INTERFACE_DETAIL_DATA structure.
                                // Returned pointer to an SP_DEVINFO_DATA structure to receive information about the device.

                                // Returns
                                // True on success.
                                //*************************************************
                                res2:=SetupDiGetDeviceInterfaceDetailA(DeviceInfoSet,@ DeviceInterfaceData,nil,0,@RequiredSize,nil);

                                DEVICE_INTERFACE_DETAIL_DATA:=AllocMem(RequiredSize+sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA));
                                DEVICE_INTERFACE_DETAIL_DATA.cbSize:=sizeof(SP_DEVICE_INTERFACE_DETAIL_DATA);

                                //Call SetupDiGetDeviceInterfaceDetail again.
                                //This time, pass a pointer to DetailDataBuffer
                                //and the returned required buffer size.
                                res3:=SetupDiGetDeviceInterfaceDetailA(DeviceInfoSet,@ DeviceInterfaceData,DEVICE_INTERFACE_DETAIL_DATA,RequiredSize,@RequiredSize,nil);
                                //************************************************
                                //Get the Devicepath to be used with createfile to get a handle for this interface
                                //************************************************
                                if res3 then
                                        begin
                                                DevicePath:=PChar(@DEVICE_INTERFACE_DETAIL_DATA.DevicePath);
                                                //10cf ed50
                                                if Pos('vid_04d8&pid_003f', DevicePath)>0 then
                                                        begin
                                                                tmp:=1;
                                                                open:=true;
                                                                hDeviceWrite := CreateFile(DevicePath, GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                                                                hDeviceRead := CreateFile(DevicePath, GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);
                                                        end;
                                                end;
                                                inc(MemberIndex);
                                                FreeMem(DEVICE_INTERFACE_DETAIL_DATA);
                                        end;
                                        SetupDiDestroyDeviceInfoList(DeviceInfoSet);
                                        givepath:=tmp;
                                end;
                        end.
