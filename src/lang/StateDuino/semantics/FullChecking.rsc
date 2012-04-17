module lang::StateDuino::semantics::FullChecking

import Map;
import List;
import Set;
import Message;
import Relation;
import Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;

public set[Message] fullCheck(StateMachine sm) {
	set[Message] result = {};
	sm = unNest(sm);
	result += checkForInvalidActionSequences(sm);
	result += checkForInvalidEnd(sm);
	return result;	
}


private set[Message] checkForInvalidActionSequences(StateMachine sm) {
	set[str] definedForks = {nm | fork(_,name(str nm), _, _) <- sm.definitions};
	set[Message] result ={};
	visit(sm) {
		case [list[Action] prefixChain, _]:
			for (a:action(nm) <- prefixChain, nm in definedForks) {
				result += {error("There should be no more actions after a call to a fork (<fixName(nm)>).", a@location)};
			}
	}
	return result;
}

private StateMachine unNest(StateMachine sm) {
	set[str] usedNames = {nm | fork(_,name(str nm), _, _) <- sm.definitions};
	usedNames += {nm | chain(name(str nm), _) <- sm.definitions};
	list[Definition] newDefinitions = [];
	StateMachine fullUnnested = sm;
	solve(fullUnnested) {
		fullUnnested = visit (fullUnnested) {
			case d:definition(f: fork(_,n:name(str nm), _, paths)) : {
				if (nm in usedNames) {
					while (nm in usedNames) {
						nm += "!";
					}
					newName = n[name = nm];
					usedNames += {nm};
					f = f[paths = visit (paths) {
						case action(n) => action(newName)
					}];
					f = f[name = newName];
				}
				newDefinitions += [f];
				insert action(f.name.name)[@location=d@location];
			}
			case d:definition(f:namelessFork(types, preActions, paths)) : {
				str nm = "nameless";	
				while (nm in usedNames) {
					nm += "!";
				}
				usedNames += {nm};
				newName = name(nm)[@location = f@location];
				newDefinitions += [fork(types, newName, preActions, paths)];
				insert action(newName.name)[@location=d@location];
			}
			case d:definition(c:chain(n:name(str nm), _)) : {
				if (nm in usedNames) {
					while (nm in usedNames) {
						nm += "!";
					}
					newName = n[name = nm];
					usedNames += {nm};
					c = c[name = newName];
				}
				newDefinitions += [c];
				insert action(c.name.name)[@location=d@location];
			}
			case f:fork(opts, n:name(str nm), pre, paths): {
				newF = f[paths = visit(paths) {
						case a:action("self") => a[name = nm] 
				}];	
				if (newF == f) {
					// we can now remove the preActions
					if (size(pre) > 0) {
						while (nm in usedNames) {
							nm += "!";
						}
						newName = n[name = nm];
						usedNames += {nm};
						newFork = f[paths = [defaultPath(pre + [last(pre)[name=nm]])]];
						newFork = newFork[preActions = []];
						f = f[forkType = opts + [immediate()]];
						f = f[name = newName];
						newDefinitions += [ newFork];
						insert f[preActions = []];
					}
				}
				else {
					insert newF;	
				}
			}
		};
		fullUnnested = fullUnnested[definitions = fullUnnested.definitions + newDefinitions];
		newDefinitions = [];
	}
	return fullUnnested;
}



private set[Message] checkForInvalidEnd(StateMachine sm) {
	set[str] definedStarts = {};
	rel[str end, loc req] endRequirements = {<sm.startFork.name, sm.startFork@location>};
	visit(sm.definitions) {
		case [_*,a:action(nm)] : endRequirements += {<nm, a@location>};	
		case name(str nm) : definedStarts += {nm};
	}
	set[str] missingDefines = domain(endRequirements) - definedStarts;
	return {*{error("<fixName(md)> is undefined", l) | l <- endRequirements[md]} | md <- missingDefines};
}

private str fixName(str nm)  { 
	if (/[_]*<pre:[^!]+>[!]+/ := nm) { 
		return pre; 
	}
	else {
		return nm;
	}
} 