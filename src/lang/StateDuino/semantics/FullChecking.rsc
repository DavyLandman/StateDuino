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

private set[Message] checkForInvalidEnd(StateMachine sm) {
	set[str] definedStarts = {};
	rel[str end, loc req] endRequirements = {<sm.startFork.name, sm.startFork@location>};
	removedPreActions = visit (sm.definitions) {
		case Definition d => (d.preActions?) ? d[preActions = []] : d
	}	
	visit(removedPreActions) {
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