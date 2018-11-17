function [ h ] = clickableLegendM( varargin )
if nargin==1
    h = legend(varargin{1});
    h.ItemHitFcn = @clickableLegendM;
elseif nargin==2
    
    if isa(varargin{2},'matlab.graphics.eventdata.ItemHitEventData')
        if ismatrix(varargin{1}) && iscell(varargin{2})
            h = legend(varargin{1}, varargin{2});
            h.ItemHitFcn = @clickableLegendM;
        else
            % This callback toggles the visibility of the line
            source = varargin{1};
            event = varargin{2};
            
            if strcmp(event.Peer.Visible,'on')   % If current line is visible
                event.Peer.Visible = 'off';      %   Set the visibility to 'off'
            else                                 % Else
                event.Peer.Visible = 'on';       %   Set the visibility to 'on'
            end
        end
    else
        h = legend(varargin{1}, varargin{2});
        h.ItemHitFcn = @clickableLegendM;
    end
end
end

