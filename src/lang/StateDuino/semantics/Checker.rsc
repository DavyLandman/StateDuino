module lang::StateDuino::semantics::Checker

import Map;
import List;
import Set;
import Message;
import Relation;
import Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;

public set[Message] fastCheck(StateMachine sm) {
	set[Message] result ={};
	visit(sm) {
		case p:param(str name, _) : 
			if (! (name in validParameterTypes)) {
				result += {error("Type <name> is not supported",p@location)};
			}
		case [_*, definition(def), list[Action] followingDefinition]:
			if (c:chain(_,_) := def) {
				result += {error("You cannot nest a chain (<c.name.name>).", c.name@location)};
			} 
			else if (size(followingDefinition) > 0) {
				result += {error("There should be no more actions after a call to a fork (<def.name? ? def.name.name : "nameless">).", def.name? ? def.name@location : def@location)};
			}
		case f:fork(_, _, _, []) : result += {emptyBodyMessage(f)};
		case f:namelessFork(_, _, []) : result += {emptyBodyMessage(f)};
		case c:chain(_, []) : result += {emptyBodyMessage(c)};
		case p:path(_, []) : result += {emptyBodyMessage(p)};
		case p:defaultPath(_, []) : result += {emptyBodyMessage(p)};
	};
	return result;
}
private Message emptyBodyMessage(Definition def) {
	if (chain(_,_) := def) {
		return emptyBodyMessage(def.name.name, "action", def.name@location);
	}
	else if (namelessFork(_,_,_) := def) {
		return emptyBodyMessage("nameless", "condition", def@location);
	}
	return emptyBodyMessage(def.name.name, "condition", def.name@location);
}
private Message emptyBodyMessage(ConditionalPath pth) 
	= emptyBodyMessage("condition", "action", pth@location);
	
private Message emptyBodyMessage(str name, str missing, loc l) = error("You must define at least one <missing> for <name>.", l);

public set[Message] fullCheck(StateMachine sm) {
	set[Message] result = fastCheck(sm);
	sm = unNest(sm);
	result += checkForInvalidActionSequences(sm);
	result += checkForInvalidStart(sm);
	result += checkForInvalidEnd(sm);
	result += checkForAlreadyDefinedNames(sm);
	return result;	
}

private set[Message] checkForInvalidStart(StateMachine sm) {
	Name target = sm.startFork;
	if (fork(_, target, _, _) <- sm.definitions) {
		return {};
	}
	return {error("<target.name> is undefined", sm.startFork@location)};
}

private set[Message] checkForInvalidActionSequences(StateMachine sm) {
	set[str] definedForks = {nm | /fork(_,name(str nm), _, _) := sm};
	set[Message] result ={};
	visit(sm) {
		case path(_, [list[Action] prefixChain, _]):
			for (a:action(name) <- prefixChain, name in definedForks) {
				result += {error("There should be no more actions after a call to a fork (<name>).", a@location)};
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


private set[Message] checkForAlreadyDefinedNames(StateMachine sm) {
	set[str] definedStarts = {};
	rel[str, loc] alreadyDefined = {};
	visit(sm.definitions) {
		case n:name(str nm) : if (nm in definedStarts) {
			alreadyDefined += {<nm, n@location>};
		} 
		else {
			 definedStarts += {nm};
		}
	}
	return {*{error("<fixName(md)> is already defined", l) | l <- alreadyDefined[md]} | md <- domain(alreadyDefined)};
}

private set[Message] checkForInvalidEnd(StateMachine sm) {
	set[Message] result = {};
	set[str] definedStarts = {};
	rel[str end, loc req] endRequirements = {};
	visit(sm) {
		case [_*,a:action(nm)] : endRequirements += {<nm, a@location>};	
		case fork(_, name(str nm), _, _) : definedStarts += {nm};
		case chain(name(str nm), _) : definedStarts += {nm};
	}
	set[str] missingDefines = domain(endRequirements) - definedStarts;
	result += {*{error("<fixName(md)> is undefined", l) | l <- endRequirements[md]} | md <- missingDefines};
	return result;
}

private str fixName(str nm)  { 
	if (/<pre:[^!]+>[!]+/ := nm) { 
		return pre; 
	}
	else {
		return nm;
	}
} 
/*
public set[Message] fullCheck(StateMachine sm) {
	set[Message] result = fastCheck(sm);
	result += checkForSingleChains(sm);
	result += checkForInvalidEnd(sm);
	result += checkAlreadyDefinedStarts(sm);
	result += checkInfinateLoops(sm);
	return result;
}

private set[Message] checkForSingleChains(StateMachine sm) {
	set[Message] result = {};
	for (chain([single]) <- sm.transitions) {
		if (action(_) := single) {
			result += {error("Single action <getName(single)> has no path to follow", single@location); };
		}	
		else if (fork(_) := single) {
			result += {error("Single fork <getName(single)> has no path to follow", single@location); };
		}	
	}
	return result;
}

private set[Message] checkAlreadyDefinedStarts(StateMachine sm) {
	set[Message] result = {};
	set[str] definedStarts = {};
	for (chain([st, _*])  <- sm.transitions) {
		str startName = getName(st);
		if (startName in definedStarts) {
			result += {error("<startName> is already defined",st@location)};	
		} 
		else {
			definedStarts += {startName};
		}
	}
	return result;
}


private set[Message] checkForInvalidEnd(StateMachine sm) {
	set[Message] result = {};
	set[str] definedStarts = {};
	rel[str end, loc req] endRequirements = {};
	visit(sm) {
		case chain([st, _*, rest:_*]) : {
				definedStarts += {getName(st)};
				if (!(forkDescription(_,_) := rest)) {
					endRequirements += {<getName(rest), rest@location>};	
				}
			}
		case fs:forkStart(fn) : {
			endRequirements += {<fn.name, fs@location>};	
		}
		case as:actionStart(an) : {
			endRequirements += {<an, as@location>};	
		}
		case chain([st:forkDescription(_,_)]) : {
				definedStarts += {getName(st)};
		}
	}
	set[str] missingDefines = domain(endRequirements) - definedStarts;
	result += {*{error("<md> is undefined", l) | l <- endRequirements[md]} | md <- missingDefines};
	return result;
}

private set[Message] checkInfinateLoops(StateMachine sm) {
	set[Message] result = {};
	// first check main chians
	set[str] loopStarts = {};
	Graph[str] states = {};
	map[str, loc] startStates = ();
	set[str] mainForks = {getName(f) | chain([_*, f:forkDescription(fn,_)]) <- sm.transitions, !(nonBlockingFork(_) := fn)};
	//set[str] mainNonBlockingForks = {getName(fn) | chain([forkDescription(fn,_)]) <- sm.transitions, (nonBlockingFork(_) := fn)};
	for (/c:chain([st,_*, end]) <- sm.transitions) {
		states += {<getName(st), getName(end)>};
		startStates[getName(st)] = st@location;
	}
	for (/f:forkDescription(nonBlockingFork(name),transitions) <- sm.transitions) {
		// since these are a kind of action lets add them to the states
		for (action(_,chain([st,_*])) <- transitions) {
			states += {<name, getName(st)>};
		}
		startStates[name] = f@location;
	}
	Graph[str] transStates = states+;
	for (str startState <- startStates) {
		if (size(transStates[startState] & mainForks) == 0) {
			loopStarts += {startState};
		}		
	}
	result += {error("<state> will never terminate, you should end in a Fork",startStates[state]) | state <- loopStarts};
	return result;
}

private str getName(StateTransition st) = (action(_) := st) ? st.action : st.name.name;

private set[Message] getInvalidForkChainMessage(StateTransition forkFrom, StateTransition to) {
	str m = "A fork (<forkFrom.name.name>) cannot be followed by another action or fork.";
	return { error(m, joinLoc(forkFrom@location, to@location))};
}

private loc joinLoc(loc left, loc right) {
	if (left.uri != right.uri) {
		throw "cannot join locations over file boundry";
	}
	loc result = left[length = left.length + right.length+ (right.offset - (left.offset + left.length))];
	result = result[end = right.end];
	return result;
}
*/