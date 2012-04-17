module lang::StateDuino::semantics::StructureChecking

import Map;
import List;
import Set;
import Message;
import Relation;
import Graph;
import IO;
import lang::StateDuino::ast::Main;
import lang::StateDuino::semantics::Concepts;


public set[Message] structureCheck(StateMachine sm) {
	set[Message] result = checkForAlreadyDefinedNames(sm);
	result += checkForDefineLoops(sm);
	return result;
}


private set[Message] checkForAlreadyDefinedNames(StateMachine sm) {
	set[Message] result = {};
	set[Name] alreadyDefined = {};
	for (d <- sm.definitions, d.name?) {
		if (d.name in alreadyDefined) {
			result += {error("<d.name.name> is already defined", d.name@location)};
		}
		alreadyDefined += {d.name};
	}
	return result;
}

private str getName(action(nm)) = nm;
private str getName(definition(d)) = "_fork";
		

private set[Message] checkForDefineLoops(StateMachine sm) {
	set[Message] result = {};
	rel[str, str] chainPaths = { *{<st.name, ac> | /action(str ac) <- acs} | chain(st, list[Action] acs) <- sm.definitions};
	chainPaths = chainPaths+;
	
	set[str] invalidChains = {};
	solve(invalidChains) {
		for (c:chain(n:name(str st),_ ) <- sm.definitions) {
			if (<st, st> in chainPaths) {
				invalidChains += {st};
				result += error("<st> has a definition loop.", n@location);
			}
			else if ((chainPaths[st] & invalidChains) > {}) {
				invalidChains += {st};
				result += error("<st> calls a chain which has a definition loop.", n@location);
			}
		}	
	}
	return result;
}

private set[Message] immediateActionsNeverFork(StateMachine sm) {

}