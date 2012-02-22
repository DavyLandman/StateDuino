module lang::StateDuino::semantics::Checker

import Map;
import List;
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
	Graph[str] states = {};
	rel[str, loc] startStates = {};
	visit (sm) {
		case chain([st, _*, end]) : {
			states += {<getName(st), getName(end)>};
			startStates += {<getName(st), st@location>};
		}
			
		case fd:forkDescription(nonBlockingFork(name), transitions): {
			// these forks do not stop so we have to act asif it's just two actions
			for (action(_,chain([st,_*])) <- transitions) {
				states += {<name, getName(st)>};
			}
		}
	}
	for (<state, state> <- states+) {
		// we have a loop
		list[str] loopRoute = shortestPathPair(states, state, state);
		result += {error("<state> will never terminate, you should end in a Fork",l) | l <- startStates[state]};
	}
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
