function [platform,address] = sdruExampleFindRadio()
%sdruExampleFindRadio Find an available USRP(TM) radio
%   [P,A] = sdruExampleFindRadio searches for available USRP
%   radios and returns the platform, P, and address, A, of the radio.

%   Copyright 2016-2023 The MathWorks, Inc.

% Find a USRP radio
connectedRadios = findsdru;
if strncmp(connectedRadios(1).Status, 'Success', 7)
  platform = connectedRadios(1).Platform;
  switch connectedRadios(1).Platform
      case {'B200','B210'}
        address = connectedRadios(1).SerialNum;
      case {'N200/N210/USRP2','X300','X310','N300','N310','N320/N321'}
        address = connectedRadios(1).IPAddress;
  end
else
  platform = 'N200/N210/USRP2';
  address = '192.168.10.2';
end
