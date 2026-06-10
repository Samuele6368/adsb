function helperAdsbCheckModelParams(varargin)
%helperAdsbCheckModelParams ADS-B Simulink example parameter check

%   Copyright 2016-2023 The MathWorks, Inc.

if evalin('base', 'exist(''adsbParam'', ''var'')')
    adsbParam = evalin('base', 'adsbParam');
    frontEndSampleRate = adsbParam.FrontEndSampleRate;
    % Get the basic ADSB configuration parameters 
    if nargin == 0 
        tmp = helperAdsbConfig(frontEndSampleRate);
    else
        platform = varargin{1}; % The Simulink USRP flow to avoid overwriting the parameters
        tmp = helperAdsbConfig(platform);
    end
    % Check if the basic ADSB configuration parameters are same for preload
    % and initialization
    if ~isequal(tmp, adsbParam)
        error(message('comm:examples:ParamsBadState'))
    end
else
    frontEndSampleRate = 2.4e6;
    adsbParam = helperAdsbConfig(frontEndSampleRate);
    assignin('base', 'adsbParam', adsbParam);
end