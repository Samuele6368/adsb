%% Airplane Tracking Using ADS-B Signals in Simulink
% This example shows how to track planes by processing automatic dependent
% surveillance-broadcast (ADS-B) signals. You can use previously captured
% signals, or receive signals in real time using an RTL-SDR radio, an
% ADALM-PLUTO radio or a USRP(TM) radio. You can also visualize the tracked
% planes on a map with Mapping Toolbox(TM).
%
% Copyright 2015-2024 The MathWorks, Inc.

%% Required Hardware and Software
% By default, this example runs using previously captured data. Optionally,
% you can receive signals over-the-air. For this, you also need one of the
% following:
%
% * RTL-SDR radio and <https://www.mathworks.com/hardware-support/rtl-sdr.html _Communications
% Toolbox Support Package for RTL-SDR Radio_>.
% * Pluto radio and <https://www.mathworks.com/hardware-support/adalm-pluto-radio.html _Communications
% Toolbox Support Package for Analog Devices(R) ADALM-PLUTO Radio_>.
% * 200-Series USRP Radio (B2xx or N2xx) and
% <https://www.mathworks.com/hardware-support/usrp.html _Communications
% Toolbox Support Package for USRP Radio_>. For information on how to map
% an NI(TM) USRP device to an Ettus Research 200-series USRP device, see
% <docid:usrpradio_ug#buzc7a6-1 _Supported Hardware and Required Software_>.
% * 300-Series USRP Radio (X3xx) and
% <https://www.mathworks.com/hardware-support/ni-usrp-radios.html _Wireless
% Testbench Support Package for NI USRP Radios_>. For information on how to
% map an NI USRP device to an Ettus Research 300-series USRP
% device, see
% <docid:wt_gs#mw_74eb94c7-dcbc-40dc-8a56-cc7bc0124002 _Supported Radio Devices_>.

%% Introduction
% For an introduction on the Mode-S signaling scheme and ADS-B technology
% for tracking aircraft, refer to the <docid:comm_ug#example-ADSBExample
% Airplane Tracking Using ADS-B Signals> MATLAB(R) example.

%% Receiver Structure
% This diagram summarizes the receiver code structure. The processing has
% four main parts: signal source, physical layer, message parser, and data
% viewer.
%
modelName = 'ADSBSimulinkExample';
open_system(modelName);
set_param(modelName, 'SimulationCommand', 'update');

%%
% *Signal Source*
%
% You can specify one of these signal sources:
%
% * |''Captured Signal''| - Over-the-air signals written to a file and
% sourced using a baseband file reader block at 2.4 Msps
% * |''RTL-SDR Radio''| - RTL-SDR radio at 2.4 Msps
% * |''ADALM-PLUTO''| - ADALM-PLUTO radio at a sample rate of 12 Msps
% * |''USRP Radio''| - USRP radio at a sample rate of 20 Msps for all
%                    radios except N310/N300 radio, that uses 2.4 Msps
%                    sample rate
%
% The extended squitter message is 120 micro seconds long, so the signal
% source is configured to process enough samples to contain 180 extended
% squitter messages simultaneously, and set |SamplesPerFrame| of the signal
% property accordingly. The rest of the algorithm searches for Mode-S
% packets in this frame of data and outputs all correctly identified
% packets. This type of processing is referred to as batch processing. An
% alternative approach is to process one extended squitter message at a
% time. This single packet processing approach incurs 180 times more
% overhead than the batch processing, while it has 180 times less delay.
% Since the ADS-B receiver is delay tolerant, you use batch processing in
% this example.

%%
% *Physical Layer*
%
% The physical layer (PHY) processes baseband samples from the signal
% source to produce packets that contain the PHY layer header information
% and the raw message bits. This diagram shows the physical layer
% structure.
%
open_system([modelName, '/PHY Layer']);
%%
% The RTL-SDR radio can use a sampling rate in the range [200e3, 2.8e6] Hz.
% When the source is an RTL-SDR radio, the example uses a sampling rate of
% 2.4 MHz and interpolates by a factor of 5 to a practical sampling rate of
% 12 MHz.
%
% The ADALM-PLUTO radio can use a sampling rate in the range [520e3,
% 61.44e6] Hz. When the source is an ADALM-PLUTO radio, the example samples
% the input directly at 12 MHz.
%
% The USRP radios are capable of using different sampling rates. When the
% source is a USRP radio, the example samples the input directly at 20 MHz.
% For the N310/N300 radio the data is received at 2.4 MHz sample rate and
% interpolates by a factor of 5 to a practical sampling rate of 12e6.
%
% For example, if the data rate is 1 Mbit/s and the effective sampling rate
% is 12 MHz, the signal contains 12 samples per symbol. The receive
% processing chain uses the magnitude of the complex symbols.
%
% The packet synchronizer works on subframes of data that is equivalent to
% two extended squitter packets, i.e. 1440 samples at 12 MHz or 120 micro
% seconds. This subframe length ensures that the subframe contains the
% whole extended squitter. Packet synchronizer first correlates the
% received signal with the 8 microsecond preamble and finds the peak value.
% The synchronizer then validates the found synchronization point by
% checking if it confirms to the preamble sequence, [1 0 0 0 0 0 1 0 1 0 0
% 0 0 0 0], where a value of 1 represents a high value and a value of 0
% represents a low value.
%
% The Mode-S PPM scheme defines two symbols. Each symbol has two chips,
% where one has a high value and the other has a low value. If the first
% chip is high and the subsequent chip is low, then the symbol is 1.
% Alternatively, if the first chip is low and subsequent chip is high, then
% the symbol is 0. The bit parser demodulates the received chips and
% creates a binary message. The CRC checker validates the binary message.
% The output of bit parser is a vector of Mode-S physical layer header
% packets that contains these fields:
%
% * RawBits - Raw message bits
% * CRCError - FALSE if CRC passes, TRUE if CRC fails
% * Time - Time of reception in seconds, from the start of reception
% * DF - Downlink format (packet type)
% * CA - Capability

%%
% *Message Parser*
%
% The message parser extracts the raw bits based on the packet type as
% described in [ <#10 2> ]. This example can parse short squitter packets
% and extended squitter packets that contain airborne velocity,
% identification, and airborne position data.

%%
% *Data Viewer*
%
% The data viewer shows the received messages on a graphical user interface
% (GUI). For each packet type, the data viewer shows the number of detected
% packets, the number of correctly decoded packets and the packet error
% rate (PER). As the radio captures data, the application lists information
% decoded from these messages in a table.
%%
% *Launch Map and Log Data*
%
% You can also launch the map and start text file logging using the two
% slider switches(Launch Map and Log Data).
%
% * *Log Data** - When Log Data is On, it Saves the captured data in a TXT
% file. You can use the saved data for later for post processing.
%
% * *Launch Map* - When Launch Map is On, map will be launched where the
% tracked flights can be viewed. *NOTE:* You must have a valid license for
% the Mapping Toolbox if you want to use this feature.
%
% These figures illustrate how the application tracks and lists flight
% details and displays them on a map.
%
% <<../sdrrTrackedFlightsOnApp.png>>
%
% <<../sdrrFlightsOnMap.png>>

%% References
% # International Civil Aviation Organization, Annex 10, Volume 4.
% Surveillance and Collision Avoidance Systems.
% # Technical Provisions For Mode S Services and Extended Squitter (Doc
% 9871)