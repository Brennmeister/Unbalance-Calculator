classdef MessdatenController < handle
	%MESSDATENCONTROLLER Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		dbc % The DatabaseController
	end
	
	methods
		function obj = MessdatenController(dbc)
			if exist('dbc', 'var')
				obj.dbc=dbc;
			else
				obj.dbc=DBController();
			end
			obj.dbc.connect();
		end
		
		function l = loadAVWithTag(obj, tag)
			%% loadAVWithTag(tag) loads all entities matching the tag
			% This function can load multiple entities.
			% The entities are returned as a cell
			% The function only searches for attribute TAG = Value
			% The function does not convert integer tag to string tag
			% Searching for a part within an assembly will not work.
			% Use findTag instead to get a list of all entities including
			% children of assemblies with the tag
			l=obj.dbc.loadEntitiesAsAV(obj.dbc.getUniqueEntityNames('.*','attribute', 'tag', 'value', tag));
		end
		function eNames = findTag(obj, tag, eRegexp, searchInAssemblies)
			%% findTag searches for the entityName containing a tag
			% Per default, it also searches in assemblies
			% The search can be limited to specific entities
			
			% Do not limit the search to specific entities
			if ~exist('eRegexp','var')
				eRegexp='.*';
			end
			% Also search in Assemblies
			if ~exist('searchInAssemblies','var')
				searchInAssemblies=true;
			end
			
			eNames{1} = obj.dbc.getUniqueEntityNames(eRegexp,'attribute', 'tag', 'value', tag);
			if searchInAssemblies
				if isnumeric(tag)
					sTag = sprintf('%d',tag);
				else
					sTag = tag;
				end
				eNames{2} = obj.dbc.getUniqueEntityNames(eRegexp,'attribute', 'zSearchTag', 'value', sprintf('%%,%s,%%',sTag));
			end
			
			
		end
		function tE = tagExists(obj,tag)
			%% tagExists checks if a the given tag is already in use
			% Returns true/false
			% Example:
			%	tE = tagExists(53)  Checks if there is a part in the DB
			%	which uses the tag 53 and returns true if there is a part
			%	and false if not
			tE=~isempty(obj.dbc.getUniqueEntityNames('.*','attribute', 'tag', 'value', tag));			
		end
		function listTagName = getAllTags(obj)
			%% getAllTags() fetchs all tags from the database
			% Alternativ implementation: SELECT DISTINCT(`nv`) FROM `eav` WHERE `a` LIKE 'tag'
			nameList = obj.dbc.getUniqueEntityNames('.*','attribute', '^tag$');
			tagList=cell(length(nameList),1);
			for ii=1:length(nameList)
				try
					tagList{ii} = obj.dbc.loadAttributeValue(nameList{ii},'tag');
				catch
					disp('debug');
				end
			end
			listTagName = [tagList, nameList];
		end
		%% Map Functions
		function siAmp = parseAmplitude(obj, amp, ampU)
			siAmp = obj.dbc.ut.parseAmplitude(amp,ampU);
		end
		function siPhase = parsePhase(obj, p, pU)
			siPhase = obj.dbc.ut.parseAmplitude(p,pU);
		end
		function siU = parseAmpPhase3(obj, amp, ampU, p, pU)
			siU=obj.dbc.ut.parseAmpPhase3(amp, ampU, p, pU);
		end
		function siMass = parseMass(obj, m, mU)
			siMass =obj.dbc.ut.parseMass(amp,  m, mU);
		end
		
		%% Test-Functions
		function [] = testFunctions(obj)
			error('go to the code for the examples');
			%% Test saving of an assembly and searching for the tag of a mounted part
			dbc = DBController();
			mdc = MessdatenController(dbc);
			
			% Create Test Part and assembly
			A=Assembly('main assembly');
			a=Assembly('Part Container');
			a.setParent(A);
			p=Part('Test Part');
			p.mass=1;
			p.setPrimitive('cylinder','length',123e-3, 'diameter', 50e-3);
			p.setParent(a);
			p.typeID = 'customTestPart';
			p.tag = 'tt2';
			pp = p.copy();
			a=Assembly('Part Container');
			pp.setParent(a);
			a.setParent(A);
			pp.tag='tt3';
			a.origin=[10 20 30];
			% Save it to the DB
			eNameP=dbc.saveObject(p,'testPart');
			eNamePP=dbc.saveObject(pp,'testPart');
			% dbc.addAttribute(eNameP,'tag','tt1');
			eNameA=dbc.saveObject(A,'testAsbly');
			
			
			% Search for Parts only with tag tt2 and tt3
			eN = mdc.findTag('tt2');
			% eN{1}{:} contains the name of the parts with the tag
			% eN{2}{:} contains the name of the assemblies with the tag
			eNN = mdc.findTag('tt3');
			
			% Delete them
			dbc.deleteEntity(eNameA);
			dbc.deleteEntity(eNameP);
			dbc.deleteEntity(eNamePP);
			
			
			%%
			dbc = DBController();
			mdc = MessdatenController(dbc);
			
			allTags = mdc.getAllTags();
			n=mdc.findTag(38);
			avs = dbc.loadEntitiesAsAV(n{1})
			av = dbc.loadEntityAsAV(n{1}{1})
		end
				
	end
end
