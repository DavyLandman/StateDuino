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


private set[Message] structureCheck(StateMachine sm) {
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
	set[str] mainForkEnds = {nm | fork(_, name(nm), _, _) <- sm.definitions} +  {"_fork"};
	rel[str, str] mainPath = {<st.name, getName(ed)> | chain(st, [_*, ed]) <- sm.definitions}+;
	
	for (c:chain(st, [_*, action(ed)]) <- sm.definitions) {
		if (!(mainPath[ed] in mainForkEnds) && !(ed in mainForkEnds)) {
			// ah we found a loop	
			result += {error("<st.name> does not end in a fork.", st@location)};
		}
	}	
	return result;
	
}