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
		case chain([_*,f:fork(_), a:_, _*]) :  
			result += getInvalidForkChainMessage(f, a);
		case chain([_*, f:forkDescription(_,_), a:_, _*]) : 
			result += getInvalidForkChainMessage(f, a);
			
		case forkDescription(_, conditions) : {
				map[str, loc] defined = ();
				for (a:action(condition,_) <- conditions) {
					if (defined[condition]?) {
						result += {error("Fork condition <condition> is already defined", a@location)};		
					}
					defined[condition] = a@location;
				}
				set[str] invalidConditions = domain(defined) - validForkConditions;
				result += {error("Fork condition <con> is not valid", defined[con]) | con <- invalidConditions};
			}
			
	};
	return result;
}

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
