classdef TEKTRONIX < Analyser
    methods
        function obj = TEKTRONIX(~,args)
            if nargin < 2
                error('Esta classe não deve ser executada diretamente.')
            end
            obj.prop = args;
        end

        function startUp(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            writeline(anl, 'DISPlay:GENeral:MEASview:SELect SPECtrum;:FORMat:DATA BIN;:SYSTem:GPS INT')
            res = writeread(anl, "SYSTEM:ERROR?");
            if ~contains(res, "No error", "IgnoreCase", true)
                warning("StartUp: " + res)
            else
                disp("Start Ok.")
            end
            clear anl;
        end    

        function res = getSpan(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            res = writeread(anl, 'SPECtrum:FREQuency:SPAN?');
            clear anl;
        end

        function res = getRes(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            res = writeread(anl, ':SPECtrum:BANDwidth:RESolution?');
            clear anl;
        end

        function out = getParms(obj)
            anl = tcpclient( obj.prop('ip'), double(obj.prop('port')) );
            keys = ["Funcion", "AVGConunt", "Detection", "Power", "FStart", "FStop", "ResAuto", "Res", "InputGain", "Att"];
            res = writeread(anl, "" + ...
                "TRACe1:SPECtrum:FUNCtion?;" + ...
                ":TRACe1:SPECtrum:AVERage:COUNt?;" + ...
                ":TRACe1:SPECtrum:DETection?;" + ...
                ":UNIT:POWer?;" + ...
                ":SPECtrum:FREQuency:STARt?;" + ...
                ":SPECtrum:FREQuency:STOP?;" + ...
                ":SPECtrum:BANDwidth:RESolution:AUTO?;" + ...
                ":SPECtrum:BANDwidth:RESolution?;" + ...
                ":INPut:GAIN:STATe?;" + ...
                ":INPut:ATTenuation?");
            data = strsplit(res, ';');
            out = dictionary(keys, data);
            %clear anl;
        end


        %
        % Comandos de operação
        %

        % Se passado o terceiro argumento faz start/stop, senão CF
        function setFreq(obj, freq, stop)
            if nargin < 3
                obj.sendCMD( sprintf("SPECtrum:FREQuency:CENTer %f", freq) );
            else
                obj.sendCMD( sprintf("SPECtrum:FREQuency:START %f;:SPECtrum:FREQuency:STOP %f", freq, stop) );
            end
        end

        function setRes(obj, res)
            if ischar(res) && contains( num2str(res),'auto','IgnoreCase', true )
                obj.sendCMD("SPECtrum:BANDwidth:RESolution:Auto On");
            else
                obj.sendCMD( sprintf("SPECtrum:BANDwidth:RESolution %f", res) );
            end
        end

        function setSpan(obj, span)
            obj.sendCMD( sprintf("SPECtrum:FREQuency:SPAN %f", span) );
        end

        function setAtt(obj, att)
            obj.sendCMD( sprintf(":INPut:ATTenuation %f", att) );
        end

        % Para atenuação de entrada < 15dB
        function preAmp(obj, state)
            if (contains(state, "On", "IgnoreCase", true)) || (contains(state, "1"))
                obj.sendCMD( sprintf(":INPut:GAIN:STATe ON") );
            else
                obj.sendCMD( sprintf(":INPut:GAIN:STATe OFF") );
            end
        end

        function data = getTrace(obj, n)
            obj.sendCMD("FORMat:DATA ASCii");
            trace = str2double( strsplit( obj.getCMDRes(sprintf("FETCh:SPECtrum:TRACe%i?", n) ), ',') );
            % TODO: Nas proximas duas linhas, SYSTEM:ERROR retorna os valores setados:
            fstart = str2double( obj.sendCMD("SPECtrum:FREQuency:START?") );
            fstop  = str2double( obj.sendCMD("SPECtrum:FREQuency:STOP?" ) );
            header = linspace(fstart, fstop, length(trace));
            % TODO: Converter para table
            data = table( num2str(header'), trace', 'VariableNames', {'freq', 'value'});
        end
    end
end

