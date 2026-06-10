function helperAdsbViewerAdaptor(msg, msgCnt, resetGUI, launchMap, logData, logFileName, lost)
%helperAdsbViewerAdaptor Adaptor to use MATLAB implementation in Simulink
%   helperAdsbViewerAdaptor is used as an adaptor to use the MATLAB
%   implementation of the helperAdsbViewer object in Simulink. This
%   function creates an helperAdsbViewer object and saves it in a
%   persistent variable. Also, the some fields of the MATLAB structures are
%   characters, which are no supported as signals in the R2016b and earlier
%   releases of Simulink. Therefore, this function converts integer valued
%   string fields into character arrays before calling the update method of
%   the helperAdsbViewer.
%
%   Since helperAdsbViewer utilizes MATLAB Graphics objects, it cannot generate
%   code and has to be defined as coder.extrinsic in a MATLAB Function
%   block. This adaptor function is used in the Data Viewer block.
%
%   See also ADSBExample, helperAdsbViewer.

%   Copyright 2015-2016 The MathWorks, Inc.

persistent viewer

if isempty(viewer)
  viewer = helperAdsbViewer;
end

if isStopped(viewer)
  start(viewer);
end

if resetGUI
  reset(viewer);
end

if (logData)
   startDataLog(viewer,logFileName);
else
   stopDataLog(viewer);
end

if (launchMap)
    if ~license('checkout', 'MAP_Toolbox') && (~viewer.licenseFlag)
        viewer.licenseFlag = 1;
        startMapUpdate(viewer);
    elseif license('checkout', 'MAP_Toolbox')
        startMapUpdate(viewer);
    end
    
else
    closeMap(viewer);
end

for p=1:msgCnt
  msg(p).ICAO24 = char(msg(p).ICAO24);
  msg(p).AirborneVelocity.HeadingSymbol = char(msg(p).AirborneVelocity.HeadingSymbol);
  msg(p).Identification.FlightID = char(msg(p).Identification.FlightID);
end

update(viewer, msg, msgCnt, lost);

    
