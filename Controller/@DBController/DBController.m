classdef DBController < handle
    %DBCONTROLLER Controller for the MySQL Database
    %   Detailed explanation goes here
    properties
        conn; % connector
        ut 					% Universal Translator
        dbName	= 'selma'
        dbUser	= 'selma'
        dbPW	= 'ADDPASSWORDHERE'
        dbURL	= 'jdbc:mysql://url-to-db-server.de:3306/'
        dbTbl	= 'eav'
        checkEntityNameOnGenerationForExistance = true    % Set to false for performance Issues
        isOpenFcn                                         % Function handle to the isopen/isconnected function (depending on Matlab version)
    end
    
    events
        DataLoaded;
    end
    
    methods
        function obj = DBController()
            obj.ut = UniversalTranslator();
            % Set the function handle to the isopen/isconnection function,
            % depending on the matlab version
            if regexp(version('-release'),'2016.*')
                obj.isOpenFcn = @isopen;
            elseif regexp(version('-release'),'2017.*')
                obj.isOpenFcn = @isopen;
            else
                obj.isOpenFcn = @isconnection;
            end
            % obj.runLocal(); % --> Einkommentieren wenn locale DB (bspw. xampp) verwendet wird
        end
        function runLocal(obj)
            % Sets the properties to run on a local mysql instance
            obj.dbName	= 'test';
            obj.dbUser	= 'root';
            obj.dbPW	= '';
            obj.dbURL	= 'jdbc:mysql://localhost:3306/';
            obj.dbTbl	= 'eav';
        end
        function obj = connect(obj)
            %% create Connector
            % add java class dynamic path in the starup: javaaddpath('.\Toolboxes\mysql-connector-java-5.0.8-bin.jar');
            
            % Set preferences with setdbprefs.
            % s.DataReturnFormat = 'cellarray';
            % s.DataReturnFormat = 'table';
            s.DataReturnFormat = 'structure';
            s.ErrorHandling = 'store';
            s.NullNumberRead = 'NaN';
            s.NullNumberWrite = 'NaN';
            s.NullStringRead = '';
            s.NullStringWrite = '';
            s.JDBCDataSourceFile = '';
            % s.UseRegistryForSources = 'yes'; % Ab Matlab v2017a nicht mehr gültig!
            %s.DefaultRowPreFetch = '10000'; % Ab Matlab v2017a nicht mehr gültig!
            setdbprefs(s);
            
            % Make connection to database.
            % Using JDBC driver .
            obj.conn = database(obj.dbName,obj.dbUser,obj.dbPW,'com.mysql.jdbc.Driver',obj.dbURL);
            
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
        end
        
        function close(obj)
            %% Close  Connection
            if ~isempty(obj.conn)
                close(obj.conn);
                obj.conn = [];
            end
        end
        function createEntity(obj, entityName, varargin)
            %% Write entity with attributes and values to DB
            % Example usage:
            %	DBController.createEntity('mag_dug12adi91z', 'mass', 0.01, 'measuredWidth', '[0,0.01; 10, 0.0101; 20, 0.0993; 30, 0.01]');
            if mod(nargin,2)==1
                error('Number of Arguments must be 1+2*n.');
            end
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            
            sql=sprintf('INSERT INTO `%s` (`e`, `a`, `nv`, `sv`) VALUES', obj.dbTbl);
            
            for ii=1:2:nargin-2
                a = varargin{ii};
                if strcmp(a,'entityName')
                    % do not Save entityName as a separate Attribute.
                    % However, a check is performed if they match.
                    if ~strcmp(entityName,varargin{ii+1})
                        error('EntityName does not match. Attribute "entityName" =%s ~= entityName of the function call = %s.', varargin{ii+1}, entityName);
                    end
                else % All Attributes but "entityName"
                    if length(varargin{ii+1})==1 && isnumeric(varargin{ii+1})
                        % The given value is a single numeric value ==> Store
                        % in nv
                        nv = varargin{ii+1};
                        sv = [];
                        sql=sprintf('%s (''%s'', ''%s'', ''%0.12f'', NULL),', sql, entityName, a, nv);
                    else
                        % Store the value in the sv-field
                        nv = NaN;
                        sv = obj.sanitize(savejson(varargin{ii+1}));
                        sql=sprintf('%s (''%s'', ''%s'', NULL, ''%s''),', sql, entityName, a, sv);
                    end
                end
            end
            
            % Remove last "," and add ";"
            sql=regexprep(sql,', *$', ';');
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
        end
        function deleteEntity(obj, varargin)
            %% Delete Entity completely
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            % Build sql Command
            for e=varargin
                sql=sprintf('DELETE FROM `%s` WHERE `e` = ''%s''; ', obj.dbTbl, obj.sanitize(e{1}));
                % Execute SQL
                curs = exec(obj.conn, sql);
                if ~isempty(curs.Message)
                    error(curs.Message);
                end
            end
        end
        function resOut = hasAttribute(obj, entityName, attribute)
            %% Check if the given entity has the attribute
            if ~ischar(attribute)
                error('Checking only supported for single attributes.')
            end
            if ~isempty(obj.getUniqueEntityNames(sprintf('^%s$', entityName),'attribute',sprintf('^%s$', attribute)))
                resOut = true;
            else
                resOut=false;
            end
        end
        function addAttribute(obj, eName, varargin)
            %% Adds the specified Attributes to the Entity
            % addAttribute is more an alias for createEntity with an
            % additional check...
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            % Cchek for existing EntityName
            if ~obj.entityExists(eName)
                error('Entity needs to exisit for adding an Attribute');
            end
            
            % Cchek for existing Attributes
            for ii=1:2:nargin-2
                if obj.hasAttribute(eName,varargin{ii})
                    error('Attribute %s already exists. Try updating instead of adding again',varargin{ii});
                end
            end
            
            obj.createEntity(eName,varargin{:});
        end
        function deleteAttribute(obj, entityName, varargin)
            %% Delete Atribute and Value of Entity
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            % Build sql Statement and execute
            for a=varargin
                sql=sprintf('DELETE FROM `%s` WHERE `e`=''%s'' AND `a`=''%s''; ', obj.dbTbl, obj.sanitize(entityName), obj.sanitize(a{1}));
                % Execute SQL
                curs = exec(obj.conn, sql);
                if ~isempty(curs.Message)
                    error(curs.Message);
                end
            end
        end
        
        function str = sanitize(obj, str)
            str = regexprep(str,'''','\\''');
            str = regexprep(str,'\\','\\\\');
            str = regexprep(str,'\n','');
        end
        
        function updateEntity(obj, entityName, varargin)
            %% Update Atribute and Value of Entity
            if mod(nargin,2)==1
                error('Number of Arguments must be 1+2*n.');
            end
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            if obj.checkEntityNameOnGenerationForExistance
                if obj.checkEntityNameOnGenerationForExistance
                    if ~obj.entityExists(entityName)
                        error('Entity does not exist');
                    end
                end
            end
            for ii=1:2:nargin-2
                if ~strcmp(varargin{ii},'entityName')
                    % Do not store the attribute entityName
                    if length(varargin{ii+1})==1 && isnumeric(varargin{ii+1})
                        % The given value is a single numeric value ==> Store
                        % in nv
                        a = varargin{ii};
                        nv = varargin{ii+1};
                        sql=sprintf('UPDATE `%s` SET `nv` = ''%0.12f'', `sv` = NULL WHERE `e`=''%s'' AND `a`=''%s'';', ...
                            obj.dbTbl, ...
                            nv, ...
                            entityName, ...
                            a);
                    else
                        % Store the value in the sv-field
                        a = varargin{ii};
                        sv = obj.sanitize(savejson(varargin{ii+1}));
                        sql=sprintf('UPDATE `%s` SET `nv` = NULL, `sv` = ''%s'' WHERE `e`=''%s'' AND `a`=''%s'';', ...
                            obj.dbTbl, ...
                            sv, ...
                            entityName, ...
                            a);
                        
                    end
                end
                % Remove last "," and add ";"
                curs = exec(obj.conn, sql);
                if ~isempty(curs.Message)
                    error(curs.Message);
                end
            end
            
        end
        function av = loadEntityAsAV(obj, entityName)
            % Loads an Entity as a Nx2 Cell with Attribute-Value Pairs
            
            % Load an Entity the (old) way
            e = obj.loadSingleEntity(entityName);
            % Remove the Struct part
            av = e.(char(fieldnames(e)));
            % Add the entity Name
            av.entityName = char(fieldnames(e));
        end
        
        function e = loadEntitiesAsAV(obj, entityNames)
            % Loads Entities as a Nx2 Cell with Attribute-Value Pairs
            % Input entityNames must be a cell!
            e = cell(length(entityNames),1);
            for ii = 1:length(entityNames)
                e{ii} = obj.loadEntityAsAV(entityNames{ii});
            end
        end
        function e = loadSingleEntity(obj, varargin)
            %% Load specified Entity
            % Usage Exmplaes:
            %	e = loadEntity('disc_1KWDH0NH37')
            entityName = varargin{1};
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            if obj.checkEntityNameOnGenerationForExistance
                if ~obj.entityExists(entityName)
                    error('Entity ''%s'' does not exist', entityName);
                end
            end
            sql = sprintf('SELECT * FROM `%s` WHERE `e` = ''%s'';', obj.dbTbl, entityName);
            % Remove last "," and add ";"
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
            cursf = fetch(curs);
            
            %% Parse Data into Matlab-Format
            for ii = 1:length(cursf.Data.e)
                if length(cursf.Data.nv(ii))>namelengthmax
                    error('Maximum length for variables exceeded!');
                end
                if ~isnan(cursf.Data.nv(ii))
                    e.(entityName).(cursf.Data.a{ii}) = cursf.Data.nv(ii);
                else
                    tmp = loadjson(cursf.Data.sv{ii});
                    e.(entityName).(cursf.Data.a{ii}) = tmp.root;
                end
            end
        end
        function e=loadEntity(obj, varargin)
            %% Load specified Entities
            % Usage Exmplaes:
            %	e = loadEntity('disc_1KWDH4KQ91', 'disc_1KWDH0NH37')
            for ii=1:nargin-1
                tmp = obj.loadSingleEntity(varargin{ii});
                e.(char(fieldnames(tmp)))=tmp.(char(fieldnames(tmp)));
            end
        end
        function eExist = entityExists(obj, entityName)
            %% Function to check if an entity exists
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            sql = sprintf('SELECT * FROM `%s` WHERE `e` = ''%s'' LIMIT 1;', obj.dbTbl, entityName);
            % Execute Query
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
            cursf = fetch(curs);
            if strcmp(cursf.Data, 'No Data')
                eExist = false;
            else
                eExist = true;
            end
        end
        function entityName = generateEntityName(obj, prefix)
            %% Function to generate an entity name
            % The Name is generated from the current datetime of the creation
            % in the format yymmddHHMMSSFFF and then base36 encoded.
            % It can be decoded by decodeEntityName(entityName)
            % Usage Example:
            %	entityName = generateEntityName()
            %	entityName = generateEntityName('mag')
            if ~exist('prefix','var')
                prefix='';
            else
                prefix = sprintf('%s_',prefix);
            end
            entityName =  sprintf(  '%s%s',prefix, dec2base(str2double(datestr(now, 'yymmddHHMMSSFFF')),36)  );
            while obj.checkEntityNameOnGenerationForExistance && obj.entityExists(entityName)
                entityName =  sprintf(  '%s%s',prefix, dec2base(str2double(datestr(now, 'yymmddHHMMSSFFF')),36)  );
            end
        end
        function info = decodeEntityName(obj, entityName)
            %% Function to decode entity Name
            % Usage Example:
            %	info = decodeEntityName('mag-1KV77NME0K')
            info = regexprep(entityName,'^.*[-_]','');
            info = sprintf('%d',base2dec(info,36));
            info = datestr(datenum(info, 'yymmddHHMMSSFFF'),'yyyy-mm-dd HH:MM:SS.FFF');
        end
        
        function entityNames = getUniqueEntityNames(obj, varargin)
            %% Function for getting unique entity names
            %	e = getUniqueEntityNames('^mag_.*$')							% Gets all Unique Entity names matching the regexp
            %	e = getUniqueEntityNames('.*', 'attribute','tag')				% Gets all Unique Entity names matching the regexp 'tag' as an attribute
            %	e = getUniqueEntityNames('.*', 'attribute','tag', 'value', '2') % Gets all Unique Entity names matching the given regexp
            inpPa = inputParser;
            inpPa.addRequired('eRegexp',				@isstr);
            inpPa.addParameter('attribute',		'.*');
            inpPa.addParameter('value',			[]);
            inpPa.parse(varargin{:})
            
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            
            % Convert Inputs to Cells
            if ~iscell(inpPa.Results.attribute)
                attr = {inpPa.Results.attribute};
            else
                if ~isempty(inpPa.Results.attribute)
                    attr = inpPa.Results.attribute;
                else
                    attr={};
                end
            end
            
            if ~iscell(inpPa.Results.value)
                if ~isempty(inpPa.Results.value)
                    val = {inpPa.Results.value};
                else
                    val={[]};
                end
            else
                val = inpPa.Results.value;
            end
            
            % Check Length of Cell-Struct
            if length(attr)~=length(val)
                error('Number of given Attributes and Values must be equal');
            end
            
            % Assign shorter variable Name for Entity
            eRegExp = inpPa.Results.eRegexp;
            
            
            
            %% Build SQL Query
            % To search for multiple Attributes/Values, Inner Join is
            % requred
            %
            % SELECT DISTINCT A1.e
            % FROM eav A1
            % JOIN eav A2 ON A1.e = A2.e
            % JOIN eav A3 ON A1.e = A3.e
            % WHERE
            % A1.a = 'discTag' AND
            % A1.nv = 105 AND
            % A2.a = 'cavityTag' AND
            % A3.a = 'initialU'
            
            sql = sprintf('SELECT DISTINCT A1.e');
            sql = sprintf('%s\nFROM eav A1', sql);
            % Add Joins
            for ii=2:length(attr)
                sql = sprintf('%s\nJOIN eav A%i ON A%i.e=A%i.e', sql, ii, ii-1, ii);
            end
            % Add Criteria
            sql = sprintf('%s\nWHERE A1.e REGEXP ''%s'' AND', sql, eRegExp);
            for ii=1:length(attr)
                sql = sprintf('%s\nA%i.a REGEXP ''%s''', sql, ii, attr{ii});
                sql = sprintf('%s AND', sql);
                % Check if value is given and of which type it ist
                % (string/numeric)
                if ~isempty(val{ii})
                    if isnumeric(val{ii})
                        sql = sprintf('%s\nA%i.nv = %d', sql, ii, val{ii});
                    else
                        sql = sprintf('%s\nA%i.sv REGEXP ''%s''', sql, ii, val{ii});
                    end
                    sql = sprintf('%s AND', sql);
                end
            end
            
            sql = sprintf('%s 1=1;', sql);
            
            %% Execute SQL Query
            % fprintf('SQL-Query: %s\n',sql);
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
            cursf = fetch(curs);
            if ~strcmp(cursf.Data,'No Data')
                entityNames = cursf.Data.e;
            else
                entityNames = [];
            end
        end
        
        function avg = getAverageNV(obj, attribute, varargin)
            %% Function to get the average numeric Value for given entities
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            
            
            sql = sprintf('SELECT AVG(`nv`) FROM `eav` WHERE `a` LIKE ''%s''', attribute);
            sql = sprintf('%s AND (',sql);
            
            ii=1;
            sql = sprintf('%s `e` LIKE ''%s''',sql, varargin{ii});
            for ii=2:nargin-2
                sql = sprintf('%s OR `e` LIKE ''%s''',sql, varargin{ii});
            end
            sql = sprintf('%s )',sql);
            % Execute Query
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
            cursf = fetch(curs);
            
            tmp = cursf.Data;
            avg = tmp.(char(fieldnames(tmp)));
        end
        
        function part = loadPartFromEntity(obj, eName)
            %% converts the specified entity to a part object
            avS = obj.loadEntityAsAV(eName);
            part = obj.ut.avToPart(obj.ut.avStructToCell(avS));  % TODO: Loaded Part is avStruct, then it gets convertet to AVCell and in ut.avToPart back again...
            part.entityName = eName;
        end
        
        function eName = createEntityFromPart(obj, part, namePrefix)
            %% Creates an entity from a part object
            % Usage Examples:
            % eName=createEntityFromPart(myPart)
            %  If myPart.entityName exists, it is used
            %  If myPart.entityname does not exist, there is an error
            % eName=createEntityFromPart(myPart,'mag')
            %  A new Name with the specified Prefix is generated
            
            if exist('namePrefix', 'var')
                % Generate a new Name
                eName = obj.generateEntityName(namePrefix);
            else
                % Name of the part should be used
                if isprop(part, 'entityName') && ~isempty(part.entityName)
                    eName = part.entityName;
                else
                    error('No Entity Name specified for the new Entity. Specify Part.entityName="abc" or use the Function as createEntityFromPart(myPart,''myPrefix'')');
                end
            end
            avC = obj.ut.partToAVCell(part);
            obj.createEntity(eName,avC{:});
        end
        
        function eName = createEntityFromAssembly(obj, asbly, namePrefix)
            %% Creates an entity from an assembly object, including all children
            % Usage Examples:
            % eName=createEntityFromAssembly(myAssembly)
            %  If myAssembly.entityName exists, it is used
            %  If myAssembly.entityname does not exist, there is an error
            % eName=createEntityFromAssembly(myAssembly,'discAsbly')
            %  A new Name with the specified Prefix is generated
            
            if exist('namePrefix', 'var')
                % Generate a new Name
                eName = obj.generateEntityName(namePrefix);
            else
                % Name of the part should be used
                if isprop(asbly, 'entityName') && ~isempty(asbly.entityName)
                    eName = asbly.entityName;
                else
                    error('No Entity Name specified for the new Entity. Specify Part.entityName="abc" or use the Function as createEntityFromPart(myPart,''myPrefix'')');
                end
            end
            avC = obj.ut.assemblyToAVCell(asbly);
            obj.createEntity(eName,avC{:});
        end
        
        function updateEntityFromPart(obj, part)
            %% Update an entity with values from a part object
            % Check needed, which attributes are already in DB and need an
            % update
            % Deleting of unused attributes is disabled since the part
            % object does not contain all informations which can possibly
            % be stored
            
            % check if the Part has an entityName
            % If not, the db can not be updated
            if isempty(part.entityName)
                error('DB can not be updated without an entityName of the Part.');
            end
            eName = part.entityName;
            
            % Loop through the attributes and check if they are already in
            % the DB.
            % If an attribute exists, it can be updated.
            % If an attribute does not exist, it needs to be created
            
            % avS = obj.ut.avCToS(obj.ut.partToAVCell(part));
            
            avC = obj.ut.partToAVCell(part);
            
            for ii = 0:size(avC,2)/2-1
                if obj.hasAttribute(eName,avC{2*ii+1})
                    obj.updateEntity(eName,avC{2*ii+1},avC{2*ii+2});
                else
                    obj.addAttribute(eName,avC{2*ii+1},avC{2*ii+2});
                end
            end
        end
        
        function info = testPerformance(obj, numE)
            %% Function to test the performance
            % Usage Example:
            %	testPerformance(100) % To generate 100 entities with the prefix test
            
            oldState = obj.checkEntityNameOnGenerationForExistance; % Save old State
            obj.checkEntityNameOnGenerationForExistance = false; % Disable Name Checking (time intensive)
            tic
            for ii = 1:numE
                e = obj.generateEntityName('test');
                fprintf('Creating Entity %s (%6.0f/%6.0f)\n', e, ii, numE);
                obj.createEntity(e,'testMass',rand(), 'testLength', rand(), 'testMatrix', rand(3,3));
            end
            tCreate = toc;
            testEntities = obj.getUniqueEntityNames('^test');
            tEntityNames = toc;
            numEDel = size(testEntities,1);
            for ii = 1:numEDel
                fprintf('Deleting Entity %s (%6.0f /%6.0f)\n', testEntities{ii}, ii, numEDel);
                obj.deleteEntity(testEntities{ii});
            end
            tDelete = toc;
            
            fprintf('Test with %d Entities\n', numE);
            fprintf('% 30s: %6.3f s\n', 'Time Creating Entities', tCreate);
            fprintf('% 30s: %6.3f s\n', 'Time Getting Entities', tEntityNames-tCreate);
            fprintf('% 30s: %6.3f s\n', 'Time Deleting Entities', tDelete-tEntityNames);
            obj.checkEntityNameOnGenerationForExistance = oldState; % Set back to old State
        end
        
        function [lo] = loadObject(obj, eName)
            %% loadObject(entityName) Loads any kind of Entity as the correct Object to Matlab
            % This function treats all entities with attribute
            % typeID=assembly as an assembly and all others as a Part
            %
            % Usage Examples:
            %	myPart  = loadObject('disc_1L55ZXLR38')
            %	myAsbly = loadObject('testAsbly_1OARYRWXBL')
            
            % Check if the entity has an attribute 'typeID' with value
            % 'assembly'. This can be done in an other way, but using a
            % precise SQL Statement (which is created by
            % getUniqueEntityNames) seems to have better performance
            if ~isempty(obj.getUniqueEntityNames(eName, 'attribute', 'typeID', 'value', 'assembly'))
                lo = obj.ut.avToAssembly(obj.ut.avStructToCell(obj.loadEntityAsAV(eName)));
            else
                lo = obj.ut.avToPart(obj.ut.avStructToCell(obj.loadEntityAsAV(eName)));
            end
        end
        function [eName] = saveObject(obj, sObj, namePrefix)
            %% saveObject(sObj, namePrefix) saves any kind of Part/Assembly to the Database
            %
            % If 'namePrefix' is set, an entityName will be created and
            % 'entityName' property of the object will be overwritten
            % If 'namePrefix' is not set, the 'entityName' of the object is
            % used.
            % 'namePrefix' is mandatory if 'entityName' is empty
            %
            % Usage Examples:
            %	eName = saveObject(myPart, 'testSave')
            
            % Check and/or create entity Name
            if exist('namePrefix', 'var')
                % Generate a new Name
                eName = obj.generateEntityName(namePrefix);
                sObj.entityName = eName;
            else
                % Name of the object should be used
                if isprop(sObj, 'entityName') && ~isempty(sObj.entityName)
                    eName = sObj.entityName;
                else
                    error('No Entity Name specified for the new Entity. Specify sObj.entityName="abc"');
                end
            end
            
            % Check which kind of Object should be saved (assembly or part)
            % and create class-independend attribute-value-cell
            if isa(sObj,'Assembly')
                avc = obj.ut.assemblyToAVCell(sObj);
                % For being able to search through the mounted parts, the
                % tags of the mounted parts are stored in a searchTag field
                avc{end+1} = 'zSearchTag';
                % Get all the tags of all the children
                tagList = sObj.getChildPropList('tag');
                % since there can be numeric tags and string tags, the
                % numeric ones need to be converted to string
                tagListString = '';
                for tagCounter = 1:length(tagList)
                    curTag = tagList{tagCounter};
                    if ~isnumeric(curTag)
                        tagListString = sprintf('%s,%s',tagListString,curTag);
                    else
                        tagListString = sprintf('%s,%d',tagListString,curTag);
                    end
                end
                tagListString = sprintf('%s,',tagListString);
                avc{end+1} = tagListString;
                
            elseif isa(sObj,'Part')
                avc = obj.ut.partToAVCell(sObj);
            else
                error('Given Object is not of class Assembly or Part.');
            end
            
            % Store everything
            obj.createEntity(eName,avc{:});
            
        end
        
        
        function av = loadAttributeValue(obj, entityName, attribute)
            %% Function for getting just the value of one specific attribute
            %	av = loadAttributeValue('disc_1OASFAQMYI','tag')		% Gets the Tag of the entity
            
            % Check Connection
            if ~obj.isOpenFcn(obj.conn)
                obj.conn = [];
                error(message('database:database:invalidConnection'));
            end
            
            % SQL-Command for selecting entity
            sql = sprintf('SELECT * FROM `eav` WHERE `e` LIKE ''%s'' AND `a` LIKE ''%s''', entityName, attribute);
            % fprintf('SQL-Query: %s\n',sql);
            % Execute Query
            curs = exec(obj.conn, sql);
            if ~isempty(curs.Message)
                error(curs.Message);
            end
            cursf = fetch(curs);
            %% Parse Data into Matlab-Format
            if length(cursf.Data.e)>1
                error('Multiple attributes ''%s'' for entity ''%s'' defined', attribute, entityName)
            else
                ii=1;
                if length(cursf.Data.nv(ii))>namelengthmax
                    error('Maximum length for variables exceeded!');
                end
                if ~isnan(cursf.Data.nv(ii))
                    av = cursf.Data.nv(ii);
                else
                    tmp = loadjson(cursf.Data.sv{ii});
                    av = tmp.root;
                end
            end
        end
        
        
        function [] = testFunctions(obj)
            error('Go into the Code to execute Code-Blocks for testing');
            %% Test-Saving and Loading of Assemblies (manually)
            dbc = DBController();
            dbc.connect();
            % Create Test Part and assembly
            a=Assembly('Test Assembly');
            p=Part('Test Part');
            p.mass=1;
            p.setPrimitive('cylinder','length',123e-3, 'diameter', 50e-3);
            p.setParent(a);
            p.typeID = 'customTestPart';
            a.origin=[10 20 30];
            % Save it to the DB
            eName=dbc.createEntityFromAssembly(a,'testAsbly');
            
            % Load it back
            aLAsAV = dbc.loadEntityAsAV(eName);
            aLAsCell = dbc.ut.avStructToCell(aLAsAV);
            aL = dbc.ut.avToAssembly(aLAsCell);
            
            aL = dbc.ut.avToAssembly(dbc.ut.avStructToCell(dbc.loadEntityAsAV(eName)));
            % Delete it
            dbc.deleteEntity(eName);
            % Check it
            dbc.getUniqueEntityNames('testAsbly')
            
            %% Test automatic saving of Part/Assembly
            dbc = DBController();
            dbc.connect();
            % Create Test Part and assembly
            a=Assembly('Test Assembly');
            p=Part('Test Part');
            p.mass=1;
            p.setPrimitive('cylinder','length',123e-3, 'diameter', 50e-3);
            p.setParent(a);
            p.typeID = 'customTestPart';
            a.origin=[10 20 30];
            % Save it to the DB
            eNameP=dbc.saveObject(p,'testPart');
            eNameA=dbc.saveObject(a,'testAsbly');
            % Load it from DB
            aL = dbc.loadObject(eNameA);
            pL = dbc.loadObject(eNameP);
            % Check if they are identically
            if strcmp(savejson(dbc.ut.assemblyToAVCell(aL)),savejson(dbc.ut.assemblyToAVCell(a)))
                fprintf('Assemblies match\n');
            else
                fprintf('Uppsss... assemblies are different.\n');
            end
            
            if strcmp(savejson(dbc.ut.partToAVCell(pL)),savejson(dbc.ut.partToAVCell(p)))
                fprintf('Parts match\n');
            else
                fprintf('Uppsss... parts are different.\n');
            end
            % Delete them
            dbc.deleteEntity(eNameA);
            dbc.deleteEntity(eNameP);
            %% Test automatic loading of Part/Assembly
            dbc = DBController();
            dbc.connect();
            myPart  = dbc.loadObject('disc_1L55ZXLR38');
            myAsbly = dbc.loadObject('testAsbly_1OARYRWXBL');
            
            
        end
        
    end
end



